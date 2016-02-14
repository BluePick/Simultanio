//
//  Constants.swift
//  Simultanio
//
//  Created by Anders Bech Mellson on 29/04/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation
import SystemConfiguration

var BROADCAST_IP = "" // Broadcast address is set on startup
var NODE_IP = "" // Set on startup

let TCP_COMM_PORT: UInt16 = 7004
let UDP_COMM_PORT: UInt16 = 7005

let COMMAND_DELAY: NSTimeInterval = 1.0

let is64bit = sizeof(Int) == sizeof(Int64)
let is32bit = sizeof(Int) == sizeof(Int32)

func randomInterval() -> Double {
  return Double.random(min: 0, max: 2)
}

func isConnectedToNetwork() -> Bool {
  var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
  zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
  zeroAddress.sin_family = sa_family_t(AF_INET)

  let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
    SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
  }

  var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
  if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == 0 {
    return false
  }

  let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
  let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0

  return (isReachable && !needsConnection) ? true : false
}