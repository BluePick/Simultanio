//
//  Clicker.swift
//  Socket-Prototype
//
//  Created by Anders Bech Mellson on 06/02/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation
import AVFoundation

class Clicker {
  private var click1Sound: SystemSoundID = 0
  private var click2Sound: SystemSoundID = 0

  //    private let av1: AVAudioPlayer?

  init() {
    let soundUrl1 = NSBundle.mainBundle().URLForResource("Click1", withExtension: "aif")
//    let soundUrl2 = NSBundle.mainBundle().URLForResource("Click2", withExtension: "aif")
    AudioServicesCreateSystemSoundID(soundUrl1!, &click1Sound)
    AudioServicesCreateSystemSoundID(soundUrl1!, &click2Sound)
    //
    //        var error: NSError?
    //        av1 = AVAudioPlayer(contentsOfURL: soundUrl1, error: &error)
  }

  func click1() {
    //        av1!.play()
    AudioServicesPlaySystemSound(click1Sound);
  }

  func click2() {
    AudioServicesPlaySystemSound(click2Sound);
  }
}