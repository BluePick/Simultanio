//
//  NetInfo.swift
//  Simultanio
//
//  Created by Anders Bech Mellson on 15/05/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation

struct NetInfo {
  // IP Address
  let host: String

  // Netmask Address
  let netmask: String

  // CIDR: Classless Inter-Domain Routing
  var cidr: Int {
    var cidr = 0
    for number in binaryRepresentation(netmask) {
      let numberOfOnes = number.componentsSeparatedByString("1").count - 1
      cidr += numberOfOnes
    }
    return cidr
  }

  // Network Address
  var network: String {
    return bitwise(&, net1: host, net2: netmask)
  }

  // Broadcast Address
  var broadcast: String {
    let inverted_netmask = bitwise(~, net1: netmask)
    let broadcast = bitwise(|, net1: network, net2: inverted_netmask)
    return broadcast
  }

  private func binaryRepresentation(s: String) -> [String] {
    var result: [String] = []
    for numbers in (split(s.characters) {$0 == "."}.map { String($0) }) {
      if let intNumber = Int(numbers) {
        if let binary = Int(String(intNumber, radix: 2)) {
          result.append(NSString(format: "%08d", binary) as String)
        }
      }
    }
    return result
  }

  private func bitwise(op: (UInt8,UInt8) -> UInt8, net1: String, net2: String) -> String {
    let net1numbers = toInts(net1)
    let net2numbers = toInts(net2)
    var result = ""
    for i in 0..<net1numbers.count {
      result += "\(op(net1numbers[i],net2numbers[i]))"
      if i < (net1numbers.count-1) {
        result += "."
      }
    }
    return result
  }

  private func bitwise(op: UInt8 -> UInt8, net1: String) -> String {
    let net1numbers = toInts(net1)
    var result = ""
    for i in 0..<net1numbers.count {
      result += "\(op(net1numbers[i]))"
      if i < (net1numbers.count-1) {
        result += "."
      }
    }
    return result
  }

  private func toInts(networkString: String) -> [UInt8] {
    return (split(networkString.characters){$0 == "."}.map { String($0) }).map{UInt8(Int($0)!)}
  }
}