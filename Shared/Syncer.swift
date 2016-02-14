//
//  Syncer.swift
//  Simultanio
//
//  Created by Anders Bech Mellson on 20/04/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation

final class Syncer {
  // Reference to the root node
  internal var node: Node!

  func predictCorrectLocalTime(executionTime: UInt64, deviceName: String) -> UInt64? {
    if let localPlayTime = predictLocalTimeFromDeviceTime(executionTime, deviceName: deviceName) {
      return (localPlayTime.uint64 + node.startTime).localTime
    } else {
      return nil
    }
  }

  func syncQualityToDevice(deviceName: String) -> Int {
    var counter = 0
    if node.observations.count > 1 {
      for (_, dict) in node.observations {
        if (dict[deviceName] != nil) {
          counter++
        }
      }
    }
    return counter
  }
  
  // Transform a timestamp from another device to a predicted local timestamp
  private func predictLocalTimeFromDeviceTime(executionTime: UInt64, deviceName: String) -> Double? {
    if node.observations.count > 1 {
      var xs: [Double] = []
      var ys: [Double] = []
      var x_mul_y: [Double] = []
      
      for pulseId in node.observations.keys {
        let observations = node.observations[pulseId]!
        if let x = observations[deviceName], y = observations[node.deviceName()] {
          xs.append(x)
          ys.append(y)
          x_mul_y.append(x * y)
        }
      }

      let n = xs.count.double
      if n > 1 {
        let sum_xs = xs.reduce(0, combine: +)
        let sum_xs_squared = xs.map{$0 * $0}.reduce(0, combine: +)
        let sum_ys = ys.reduce(0, combine: +)
        let sum_x_mul_y = x_mul_y.reduce(0, combine: +)

        // Calculate the linear regression function
        let m = (n * sum_x_mul_y - sum_xs * sum_ys) / (n * sum_xs_squared - sum_xs * sum_xs)
        let b = (sum_ys - m * sum_xs) / n
        let result = m * executionTime.double + b

        // Calculate the precision
        let yAverage = sum_ys / n
        let SST = ys.map{$0 - yAverage}.map{$0 * $0}.reduce(0, combine: +)
        var SSE: Double = 0
        for (i,y) in ys.enumerate() {
          let x1 = xs[i]
          let x2 = m * x1 + b
          let x3 = x2 - y
          SSE += x3 * x3
        }
        SSE = SST - SSE
        let SSR = SSE / SST

        let precision = "Precision \(SSR*100)% based on \(n) readings"
        print(precision)
        //        if let writer = node.linearResultsWriter {
        //          let algorithm = "\(m) \(b/NSEC_PER_SEC.double)"
        //          writer(xs, ys, algorithm)
        //        }

        return result
      } else {
        return nil
      }
    } else {
      return nil
    }
  }
}