//
//  NodeInfo.swift
//  Socket-Sync
//
//  Created by Anders Bech Mellson on 13/04/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation

final class NodeInfo {
  let host: String
  let port: UInt16
  var lastSeen: NSDate
  let startTime: UInt64
  let deviceName: String

  init(host: String, port: UInt16, lastSeen: NSDate, startTime: UInt64, deviceName: String) {
    self.host = host
    self.port = port
    self.lastSeen = lastSeen
    self.startTime = startTime
    self.deviceName = deviceName
  }
}