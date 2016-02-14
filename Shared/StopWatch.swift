//
//  StopWatch.swift
//  Socket-Sync
//
//  Created by Anders Bech Mellson on 23/03/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation

class StopWatch {
  private var startTime: UInt64 = 0
  func start() {
    startTime = mach_absolute_time()
  }
  
  private var stopTime: UInt64 = 0
  func stop() {
    stopTime = mach_absolute_time()
  }
  
  func getTimeElapsedNs() -> UInt64 {
    return stopTime - startTime
  }
  
  func getTimeElapsedMs() -> UInt64 {
    return (stopTime - startTime).ms
  }
}