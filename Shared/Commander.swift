//
//  TcpCommunicator.swift
//  Simultanio
//
//  Created by Anders Bech Mellson on 25/04/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation
import AVFoundation

final class Commander {
  internal var node: Node!
  private let sw = StopWatch()

  func execute(message: Message) {
    if message.deviceName != node.deviceName() {
      if let localPlayTime = node.syncer.predictCorrectLocalTime(message.executionTime, deviceName: message.deviceName) {
        if localPlayTime < mach_absolute_time() {
          print("sorry command was \((mach_absolute_time() - localPlayTime).double/NSEC_PER_SEC.double) seconds ago")
        } else {
          print("Buffer \((localPlayTime - mach_absolute_time()).double/NSEC_PER_SEC.double)s")
          switch message.type {
          case .Play:
            play(message.songName, atTime: localPlayTime)
          case .Jump:
            jump(message.jumpTime, atTime: localPlayTime)
          default:
            print("no command to perform")
          }
        }
      } else {
        node.setDisplay!("Not enough sync data")
      }
    }
  }

  func cmdDelay() -> (local: UInt64, global: UInt64) {
    let delay = mach_absolute_time().globalTime + (COMMAND_DELAY * NSEC_PER_SEC.double).uint64
    let corrected = delay - node.startTime
    return (local: delay.localTime, global: corrected)
  }

  func playClick(atTime: UInt64) {
    HPTimer(trigger: atTime) {
      self.node.clicker.click1()
    }
  }

  func stopMusic() {
    if let player = node.audioPlayer where player.playing {
      player.stop()
      player.currentTime = 0
      player.prepareToPlay()
      node.setDisplay!("Stopped")
      testStopped = true
    }
    if let midiBrain = node.mtcGenerator where midiBrain.playing {
      midiBrain.stop() // Double stop to go back to zero
      midiBrain.stop()
    }
  }

  func play() {
    node.tcpCommunicator.sendPlayCommand(cmdDelay().global)
    node.commander.play(node.currentSong, atTime: cmdDelay().local)
  }

  private func play(songname: String, atTime: UInt64) {
    if node.currentSong != songname {
      setSong(songname)
    }
    switch songname {
    case node.songs.last!: // MTC
      playMTC(atTime)
    default:
      playMusic(atTime)
    }
  }

  private func playMTC(atTime: UInt64) {
    if let midiBrain = node.mtcGenerator {
      HPTimer(trigger: atTime) {
        midiBrain.start()
      }
    }
  }

  private var offsetNegative = false
  private var timerOffset: UInt64 = 0
  private var playerOffset: UInt64 = 0
  // Calibrate the local offset of the timer and the audio player
  func calibrateOffset() {
    var offsets: [Int] = []
    var playerDelays: [Int] = []
    if let player = self.node.audioPlayer {
      for x in 0...10 {
        Async.main {
          self.node.setDisplay!("Calibrating \(x)/10")
        }

        player.currentTime = 0
        player.play()
        player.stop()

        let atTime = mach_absolute_time() + ((0.3 * NSEC_PER_SEC.double).uint64).localTime
        HPTimer(trigger: atTime) {
          let now = mach_absolute_time()
          self.sw.start()
          player.play()
          self.sw.stop()
          print("\(self.sw.getTimeElapsedMs())Ms to start playing")

          if self.sw.getTimeElapsedMs() < 1 || self.sw.getTimeElapsedMs() > 100 {
            print("outlier discarding calibration")
          } else {
            // Update offset
            offsets.append(Int(now)-Int(atTime))
            playerDelays.append(self.sw.getTimeElapsedNs().int)
          }
        }
        mach_wait_until(mach_absolute_time() + ((0.5 * NSEC_PER_SEC.double).uint64).localTime)
      }
    }
    timerOffset = (offsets.reduce(0, combine: +) / offsets.count).uint64
    playerOffset = (playerDelays.reduce(0, combine: +) / playerDelays.count).uint64
    setSong(node.songs.first!)
    Async.main {
      self.node.setDisplay!("Node started")
    }
    print("timerOffset \(timerOffset.globalTime)ns, playerOffset \(playerOffset.ms)ms")
  }

  private func playMusic(atTime: UInt64) {
    if let player = self.node.audioPlayer {
      if player.playing {
        player.stop()
        player.currentTime = 0
      }

      // Trick to get a faster start
      player.play()
      player.stop()

      let playTime = atTime - timerOffset - playerOffset
      HPTimer(trigger: playTime) {
        self.sw.start()
        player.play()
        self.sw.stop()
        if self.sw.getTimeElapsedMs() > 100 {
          player.stop()
          self.node.setDisplay!("Error - player too slow")
        } else {
          self.updatePlaybackPosition()
        }
      }
    }
  }

  private func stringFromPlayer(player: AVAudioPlayer) -> String {
    let res =  "\(stringFromSeconds(player.currentTime))/\(stringFromSeconds(player.duration))"
    return res
  }

  private func stringFromSeconds(seconds: Double) -> String {
    let hours = Int((seconds / 60 / 60) % 60)
    let minutes = Int((seconds / 60) % 60)
    let seconds = Int(seconds % 60)
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }

  func updatePlaybackPosition() {
    Async.main(after: 0.2) {
      if let player = self.node.audioPlayer where player.playing {
        self.node.setDisplay!(self.stringFromPlayer(player))
        self.updatePlaybackPosition()
      }
    }
  }

  func jumpBack() {
    if let player = node.audioPlayer where player.playing {
      var newPlayTime = -5.0 + player.currentTime
      if newPlayTime < 0 {
        newPlayTime = 0
      }
      node.tcpCommunicator.sendJumpCommand(cmdDelay().global, jumpTime: newPlayTime)
      jump(newPlayTime, atTime: cmdDelay().local)
    }
  }

  func jumpForward() {
    if let player = node.audioPlayer where player.playing {
      let newPlayTime = 5.0 + player.currentTime
      node.tcpCommunicator.sendJumpCommand(cmdDelay().global, jumpTime: newPlayTime)
      jump(newPlayTime, atTime: cmdDelay().local)
    }
  }

  var currentlyJumping = false
  private func jump(toTime: NSTimeInterval, atTime: UInt64) {
    if !currentlyJumping {
      if let player = self.node.audioPlayer where player.playing {
        self.currentlyJumping = true
        HPTimer(trigger: atTime) {
          player.stop()
          player.currentTime = toTime
          player.play()
          self.currentlyJumping = false
          self.updatePlaybackPosition()
        }
      }
    }
  }

  func setSong(song: String) {
    node.currentSong = song
    node.setSong!(song)
    switch song {
    case node.songs.last!: // MTC
      node.mtcGenerator = MTCGenerator(setDisplay: node.setDisplay!)
      print("midi time code")
    default:
      var ext = "mp3"
      if song == "test2" {
        ext = "m4a"
      }
      let songUrl = NSBundle.mainBundle().URLForResource(song, withExtension: ext)
      do {
        node.audioPlayer = try AVAudioPlayer(contentsOfURL: songUrl!)
      } catch let error1 as NSError {
        print(error1)
        node.audioPlayer = nil
      }
      node.audioPlayer!.play()
      node.audioPlayer!.stop()
      self.node.setDisplay!(self.stringFromPlayer(node.audioPlayer!))
    }
  }

  var testRun = 1
  let maxTestRuns = 60
  var testStopped = false
  func runShortTest() {
    if testStopped {
      testRun = 1
      testStopped = false
    } else {
      node.setDisplay!("Starting test \(testRun) out of \(maxTestRuns)")
      if node.observations.count > 10 {
        node.commander.play()
        Async.userInitiated(after: 15.0) {
          if self.testRun++ < self.maxTestRuns {
            self.play()
            self.runShortTest()
          } else {
            self.node.setDisplay!("Test finished")
            self.testRun = 1
          }
        }
      } else {
        let missingPulses = 10 - node.observations.count
        node.setDisplay!("Missing \(missingPulses) pulses")
        Async.userInitiated(after: missingPulses.double) {
          self.runShortTest()
        }
      }
    }
  }
}