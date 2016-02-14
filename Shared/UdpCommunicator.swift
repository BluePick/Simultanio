//
// Created by Anders Bech Mellson on 13/04/15.
// Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation

final class UdpCommunicator: NSObject, GCDAsyncUdpSocketDelegate {
  // Reference to the root node
  internal var node: Node!

  internal var socket: GCDAsyncUdpSocket!
  internal var error: NSError?

  override init() {
    super.init()
    setupConnection()
  }

  private func setupConnection() {
    socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())

    // Only use IPv4 because IPv6 does not support broadcasting
    socket.setIPv4Enabled(true)
    socket.setIPv6Enabled(false)

    do {
      try socket.enableBroadcast(true)
    } catch let error1 as NSError {
      error = error1
    }
    do {
      try socket.bindToPort(UDP_COMM_PORT)
    } catch let error1 as NSError {
      error = error1
    }
    do {
      try socket.beginReceiving()
    } catch let error1 as NSError {
      error = error1
    }
  }

  private var keepPulsing = true
  func start() {
    sendPulse()
    startPulse(randomInterval())
  }

  func stop() {
    keepPulsing = false
  }

  private func startPulse(rate: NSTimeInterval) {
    Async.userInitiated(after: rate) {
      self.sendPulse()
      }.userInitiated {
        if self.keepPulsing {
          self.startPulse(randomInterval())
        } else {
          self.keepPulsing = true
        }
    }
  }

  private func sendPulse() {
    let discovery = pulse(node.deviceName(), deviceStartTime: node.startTime)
    socket.sendData(discovery, toHost: BROADCAST_IP, port: UDP_COMM_PORT, withTimeout: -1, tag: 0)
  }

  private var lastObservationTime: Double = 0
  func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!, andTimeReceived timeReceived: UInt64) {
    let addressOfSender = GCDAsyncUdpSocket.hostFromAddress(address)
    let portOfSender = GCDAsyncUdpSocket.portFromAddress(address)

    if !node.isLocalIP(addressOfSender) {
      let message = fromData(data)
      switch message.type {
      case .Pulse:

        // Update observations
        let observedTime = (timeReceived.globalTime - node.startTime).double
        if lastObservationTime == 0 {
          lastObservationTime = observedTime
        } else {
          lastObservationTime = observedTime
          node.observations[message.pulseId] = [node.deviceName(): observedTime]
          sendPulseObservation(message.pulseId, observedTime: observedTime)
        }

        // Update connected nodes
        if let nodeInfo = node.connectedNodes[addressOfSender] {
          if nodeInfo.startTime == message.deviceStartTime {
            nodeInfo.lastSeen = NSDate()

            // If we are not already connected to this node on the tcp output, then connect to it
            if (node.tcpCommunicator.outSockets.filter{$0.connectedHost != nil && $0.connectedHost == nodeInfo.host}.count == 0) {
              node.tcpCommunicator.connectToNode(nodeInfo)
            }
          } else {
            // The node has restarted, remove old entries and add the node again
            node.connectedNodes.removeValueForKey(addressOfSender)
            var counter = 0
            for (u, dict) in node.observations {
              var cleanedDict = dict
              if (cleanedDict.removeValueForKey(node.deviceName()) != nil) {
                node.observations[u] = cleanedDict
                counter++
              }
            }
            let nodeInfo2 = NodeInfo(host: nodeInfo.host, port: nodeInfo.port, lastSeen: NSDate(), startTime: message.deviceStartTime, deviceName: nodeInfo.deviceName)
            node.connectedNodes[addressOfSender] = nodeInfo2
            node.tcpCommunicator.connectToNode(nodeInfo2)
          }
        } else {
          print("Adding new node \(addressOfSender):\(portOfSender)")
          // New node, add to dictionary
          let nodeInfo = NodeInfo(host: addressOfSender, port: portOfSender, lastSeen: NSDate(), startTime: message.deviceStartTime, deviceName: message.deviceName)
          node.connectedNodes[addressOfSender] = nodeInfo
          node.tcpCommunicator.connectToNode(nodeInfo)
        }
      case .PulseObservation:
        if node.observations[message.pulseId]?.count > 0 {
          node.observations[message.pulseId]![message.deviceName] = message.observationTime
        }
      default:
        print("UdpCommunicator received \(message.type.description)")
      }
    }
  }

  private func sendPulseObservation(pulseId: String, observedTime: Double) {
    socket.sendData(pulseObservation(pulseId, observationTime: observedTime, deviceName: node.deviceName()), toHost: BROADCAST_IP, port: UDP_COMM_PORT, withTimeout: -1, tag: 0)
  }
}
