//
// Created by Anders Bech Mellson on 19/04/15.
// Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation

extension UInt64 {
  var localTime: UInt64 {
    var s_timebase_info = mach_timebase_info(numer: 0, denom: 0)
    if (s_timebase_info.denom == 0) {
      mach_timebase_info(&s_timebase_info)
      //      println("Denom \(s_timebase_info.denom) Numer \(s_timebase_info.numer)")
    }
    return self * UInt64(s_timebase_info.denom) / UInt64(s_timebase_info.numer)
  }

  var globalTime: UInt64 {
    var s_timebase_info = mach_timebase_info(numer: 0, denom: 0)
    if (s_timebase_info.denom == 0) {
      mach_timebase_info(&s_timebase_info)
      //      println("Denom \(s_timebase_info.denom) Numer \(s_timebase_info.numer)")
    }
    return self * UInt64(s_timebase_info.numer) / UInt64(s_timebase_info.denom)
  }

  var ms: UInt64 {
    return self.globalTime / NSEC_PER_MSEC
  }

  var double: Double {
    return Double(self)
  }

  var int: Int {
    return Int(self)
  }

  func highNibble() -> String {
    return String(format:"%X", self >> 4)
  }

  func lowNibble() -> String {
    return String(format:"%X", self & 0x0F)
  }
}

extension Int {
  var double: Double {
    return Double(self)
  }

  var uint64: UInt64 {
    return UInt64(self)
  }
}

extension Double {
  var uint64: UInt64 {
    return UInt64(self)
  }

  private static func random() -> Double {
    return Double(arc4random()) / 0xFFFFFFFF
  }

  public static func random(min min: Double, max: Double) -> Double {
    return Double.random() * (max - min) + min
  }
}