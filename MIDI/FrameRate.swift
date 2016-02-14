//
//  FrameRate.swift
//  MTC Generator
//
//  Created by Anders Bech Mellson on 05/02/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation

enum FrameRate: UInt8 {
  case FPS_24, FPS_25, FPS_30_DropFrame, FPS_30

  var doubleValue: Double {
    get {
      switch self {
      case .FPS_24:
        return 24.0
      case .FPS_25:
        return 25.0
      case .FPS_30_DropFrame:
        return 29.97
      case .FPS_30:
        return 30.0
      }
    }
  }

  var quarterFrameLengthNs: UInt64 {
    get {
      let quarterframe = 4.0
      let intervalInMs = (self.doubleValue * quarterframe) / 10.0
      let intervalInNs = UInt64(intervalInMs * 1000000.0)
      return intervalInNs
    }
  }

  var binary: String {
    get {
      let binary = String(self.rawValue, radix: 2)
      if binary.characters.count == 1 {
        return "0" + binary
      }
      else {
        return binary
      }
    }
  }
}
