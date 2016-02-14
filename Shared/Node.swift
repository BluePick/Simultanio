//
//  Node.swift
//  Socket-Sync
//
//  Created by Anders Bech Mellson on 13/04/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation
import AVFoundation

final class Node {
  let startTime = mach_absolute_time().globalTime
  let commander: Commander
  let syncer: Syncer
  let tcpCommunicator: TcpCommunicator
  let udpCommunicator: UdpCommunicator

  // Audio stuff
  var audioPlayer: AVAudioPlayer?
  let clicker = Clicker()
  !!!error fix this before running!!! let songs = ["yourmusic1", "yourmusic2", "mtc"] // Add your own mp3 files to the audio directory for this to work, etc yourmusic1.mp3...
  var currentSong: String = ""
  var setSong: (String -> ())?

  // Used for updating the text label
  var setDisplay: (String -> ())?

  // MIDI stuff
  var mtcGenerator: MTCGenerator?

  // Used for writing linear regression calculations to disk for use in R
  var linearResultsWriter: (([Double],[Double],String) -> () )?

  // Function used to turn ui controls on / off
  var enablePlayerControls: (Bool -> ())?

  init() {
    commander = Commander()
    syncer = Syncer()
    tcpCommunicator = TcpCommunicator()
    udpCommunicator = UdpCommunicator()
    commander.node = self
    syncer.node = self
    tcpCommunicator.node = self
    udpCommunicator.node = self
  }

  typealias IP = String
  internal var connectedNodes: [IP:NodeInfo] = [:]

  typealias PulseID = String
  typealias DeviceName = String
  typealias ObservedTime = Double
  internal var observations: [PulseID:[DeviceName:ObservedTime]] = [:]

  func startNode() {
    localIPAddresses = getIFAddresses()
    // It seems that the device's correct IP is the last in the array
    BROADCAST_IP = localIPAddresses.last!.broadcast
    NODE_IP = localIPAddresses.last!.host

    // Setup AVAudioPlayer for local playback
    let songUrl = NSBundle.mainBundle().URLForResource("silence", withExtension: "mp3")
    do {
      audioPlayer = try AVAudioPlayer(contentsOfURL: songUrl!)
    } catch let error1 as NSError {
      print(error1)
      audioPlayer = nil
    }

    udpCommunicator.start()
  }

  func stopNode() {
    udpCommunicator.stop()
  }

  private var deviceNameStore: String?
  func deviceName() -> String {
    if let deviceName = deviceNameStore {
      return deviceName
    }
    var name = ""
    let model: NSString = DeviceInfo.model()
    if model.containsString("x86") {
      name = "Mac"
    } else {
      name = "iOS"
    }
    deviceNameStore = "\(name)-\(NODE_IP)"
    return deviceNameStore!
  }

  // Node Info Table View
  var updateTableView: (((String, String)) -> ())?
  func setNodeInfo(updateTableView: ((String, String)) -> ()) {
    self.updateTableView = updateTableView
    updateNodeInfo()
  }

  func updateNodeInfo() {
    Async.main(after: 1) {
      for (_,nodeInfo) in self.connectedNodes {
        var infoString = ""

        let numberOfSyncReadings = self.syncer.syncQualityToDevice(nodeInfo.deviceName)
        if nodeInfo.lastSeen.timeIntervalSinceNow < -10 {
          let sec = abs(Int(round(nodeInfo.lastSeen.timeIntervalSinceNow)))
          infoString = "Missing for \(sec) seconds"
        }
        if nodeInfo.lastSeen.timeIntervalSinceNow < -60 {
          infoString = "Disconnected"
        }
        if infoString.isEmpty && numberOfSyncReadings == 0 {
          infoString = "Awaiting sync"
        }
        else if infoString.isEmpty && numberOfSyncReadings < 10 {
          infoString = "Syncing \(numberOfSyncReadings)/10"
        }
        else if infoString.isEmpty && numberOfSyncReadings >= 10 {
          infoString = "Ready"
        }

        let x = infoString
        self.updateTableView!(nodeInfo.deviceName, x)
      }
      self.updateNodeInfo()
    }
  }

  // Get the local ip addresses used by this node
  func getIFAddresses() -> [NetInfo] {
    var addresses = [NetInfo]()

    // Get list of all interfaces on the local machine:
    var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
    if getifaddrs(&ifaddr) == 0 {

      // For each interface ...
      for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
        let flags = Int32(ptr.memory.ifa_flags)
        var addr = ptr.memory.ifa_addr.memory

        // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
        if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
          if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {

            // Convert interface address to a human readable string:
            var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
            if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
              nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                if let address = String.fromCString(hostname) {

                  var net = ptr.memory.ifa_netmask.memory
                  var netmaskName = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                  getnameinfo(&net, socklen_t(net.sa_len), &netmaskName, socklen_t(netmaskName.count),
                    nil, socklen_t(0), NI_NUMERICHOST) == 0
                  if let netmask = String.fromCString(netmaskName) {
                    addresses.append(NetInfo(host: address, netmask: netmask))
                  }
                }
            }
          }
        }
      }
      freeifaddrs(ifaddr)
    }
    return addresses
  }

  var localIPAddresses: [NetInfo] = []
  func isLocalIP(host: String) -> Bool {
    return localIPAddresses.filter{$0.host == host}.count > 0
  }
}
