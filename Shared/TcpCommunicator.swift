//
//  TcpCommunicator.swift
//  Simultanio
//
//  Created by Anders Bech Mellson on 25/04/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation

final class TcpCommunicator: NSObject, GCDAsyncSocketDelegate  {
  internal var listenSocket: GCDAsyncSocket!
  var outSockets: [GCDAsyncSocket] = []
  var inSockets: [GCDAsyncSocket] = []
  internal var node: Node!
  internal var error: NSError?

  override init() {
    super.init()
    setupConnection()
  }

  private func setupConnection() {
    listenSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
    do {
      try listenSocket.acceptOnPort(TCP_COMM_PORT)
    } catch let error1 as NSError {
      error = error1
    }
  }

  internal func connectToNode(node: NodeInfo) {
    let talkSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
    do {
      try talkSocket.connectToHost(node.host, onPort: TCP_COMM_PORT)
    } catch let error1 as NSError {
      error = error1
    }
    talkSocket.readDataWithTimeout(-1, tag: 0)
    inSockets = inSockets.filter { $0.isConnected }
    inSockets.append(talkSocket)
  }

  private func sameSocket(s1: GCDAsyncSocket, s2: GCDAsyncSocket) -> Bool {
    return s1.connectedHost == s2.connectedHost && s1.connectedPort == s2.connectedPort
  }

  func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
    outSockets = outSockets.filter { $0.isConnected && $0.connectedHost != newSocket.connectedHost }
    outSockets.append(newSocket)
  }

  func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
    sock.readDataWithTimeout(-1, tag: 0)
  }

  func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
    let message = fromData(data)
    switch message.type {
    case .SetSong:
      node.commander.setSong(message.deviceName)
    case .Stop:
      node.commander.stopMusic()
    default:
      node.commander.execute(message)
    }

    sock.readDataWithTimeout(-1, tag: 0)
  }

  private func sendData(data: NSData) {
    for s in outSockets {
      s.writeData(data, withTimeout: -1, tag: 0)
    }
  }

  func sendStopCommand() {
    sendData(getStopCommand())
  }

  func sendPlayCommand(executionTime: UInt64) {
    sendData(getPlayCommand(executionTime, songName: node.currentSong, deviceName: node.deviceName()))
  }

  func sendJumpCommand(executionTime: UInt64, jumpTime: Double) {
    sendData(getJumpCommand(executionTime, jumpTime: jumpTime, deviceName: node.deviceName()))
  }

  func sendSetSongCommand(song: String) {
    sendData(getSetSongCommand(song))
  }
}