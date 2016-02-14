//
//  HPTimer.swift
//  Socket-Sync
//
//  Created by Anders Bech Mellson on 01/04/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

// Swift wrapper around a high precision timer by Ulrich Zurucker, http://sononum.net

import Foundation

class HPTimer {
  private var interval: UInt64?
  private var action: so_hptimer_action?
  private var mHPTimer: so_hptimer = nil
  private let stopWatch = StopWatch()

  init(trigger: UInt64, action: so_hptimer_action) {
    so_hptimer_create(&mHPTimer, trigger)
    let actionWithDispose: so_hptimer_action = {
      action()
      self.dispose()
    }
    so_hptimer_set_action(mHPTimer, actionWithDispose)
    so_hptimer_wait(mHPTimer)
  }

  init(interval: UInt64) {
    self.interval = interval
    so_hptimer_create(&mHPTimer, interval)
  }

  func setAction(action: so_hptimer_action) {
    self.action = action
    addTimer()
  }

  func addTimer() {
    let actionWithTimer: so_hptimer_action = {
      self.stopWatch.stop()
      self.action!()
      self.stopWatch.start()
    }
    so_hptimer_set_action(mHPTimer, actionWithTimer)
  }

  func wait() {
    if action != nil {
      so_hptimer_wait(mHPTimer)
    } else {
      noActionSet()
    }
  }

  func start() {
    if action != nil {
      so_hptimer_resume(mHPTimer)
    } else {
      noActionSet()
    }
  }

  func stop() {
    if action != nil {
      so_hptimer_suspend(mHPTimer)
    } else {
      noActionSet()
    }
  }

  private func noActionSet() {
    print("No action set for this timer")
  }

  func setInterval(interval: UInt64) {
    so_hptimer_set_interval(mHPTimer, interval)
  }

  func setMaxRepetitions(max_reps: UInt64) {
    so_hptimer_set_maxrepetitions(mHPTimer, max_reps)
  }

  func dispose() {
    so_hptimer_dispose(mHPTimer)
  }
}