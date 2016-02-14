//
//  MTCGenerator.swift
//  MTC Generator
//
//  Created by Anders Bech Mellson on 02/02/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation
import CoreMIDI

final class MTCGenerator {
  // Framerate of the brain
  private let framerate = FrameRate.FPS_25

  // Used for timing conversions
  private var info = mach_timebase_info(numer: 0, denom: 0)

  // Control and display
  var playing = false
  private var setDisplay: (String -> ())

  // Midi References
  private var client = MIDIClientRef()
  private var midiOut = MIDIEndpointRef()

  // special port for the mtc tester
  private var mtcOut = MIDIEndpointRef()
  private var mtcTester = MIDIEndpointRef()
  private var sendToTester = false

  private var packetList = UnsafeMutablePointer<MIDIPacketList>.alloc(sizeof(MIDIPacketList))
  private let packetListSize = sizeof(MIDIPacketList)
  private var packet = UnsafeMutablePointer<MIDIPacket>.alloc(sizeof(MIDIPacket))

  init(setDisplay: (String -> ())) {
    self.setDisplay = setDisplay
    mach_timebase_info(&info)
    MIDIClientCreate("Simultanio MTC", nil, nil, &client)
    MIDISourceCreate(client, "Simultanio MTC", &midiOut)

    // Setup the correct timebase
    if (info.denom == 0) {
      mach_timebase_info(&info)
    }
    correctedQuarterFrameLength = correctWait(framerate.quarterFrameLengthNs)
    tick = correctedQuarterFrameLength * 8 // 8 Quarter frames in one tick

//    // Connect to the MTC Tester application if it is running
//    let numberOfMidiDestinations = MIDIGetNumberOfDestinations()
//    for i in 0...numberOfMidiDestinations {
//      let midiDestination = MIDIGetDestination(i)
//      var name: Unmanaged<CFString>?
//      MIDIObjectGetStringProperty(midiDestination, kMIDIPropertyDisplayName, &name)
//      if let deviceName = name?.takeRetainedValue() {
//        if deviceName == "Time Code Tester" {
//          MIDIOutputPortCreate(client, "MTC Generator", &mtcOut)
//          mtcTester = midiDestination
//          sendToTester = true
//        }
//      }
//    }
  }

  private func sendFullMTC() {
    packet = MIDIPacketListInit(packetList)
    var delay: UInt64 = 0
    for value in quarterFrameMessages {
      let playTime: CoreMIDI.MIDITimeStamp = now - startOffset + delay
      packet = MIDIPacketListAdd(packetList,
        packetListSize,
        packet,
        playTime,
        2,
        value)
      delay += framerate.quarterFrameLengthNs
    }
    MIDIReceived(midiOut, packetList)

//    if sendToTester {
//      MIDISend(mtcOut, mtcTester, packetList)
//    }

    packet.destroy()
    packetList.destroy()
  }

  private func convertToByte(part: Int, hexValue: String) -> UInt8 {
    let scanner = NSScanner(string: "\(part)\(hexValue))")
    var result: UInt32 = 0
    scanner.scanHexInt(&result)
    return UInt8(result)
  }

  private func correctWait(wait: UInt64) -> UInt64 {
    let correctedSecond = UInt32(wait) * info.denom / info.numer
    return UInt64(correctedSecond)
  }

  private var quarterFrameMessages: [[UInt8]] = [[],[],[],[],[],[],[],[]]
  private var now: UInt64 = 0, tick: UInt64 = 0, startTime: UInt64 = 0, startOffset: UInt64 = 0, correctedQuarterFrameLength: UInt64 = 0

  // TODO Remember When MTC is running in reverse these are sent in the opposite order,
  // ie, the Hours High Nibble is sent first and the Frames Low Nibble is last.
  func start() {
    playing = true
    numberOfStopPushes = 0
    startTime = mach_absolute_time() + tick
    now = startTime + startOffset + correctedQuarterFrameLength
    prepareMidiTimeCode()
    Async.userInitiated {
      self.run()
    }
  }

  private func run() {
    sendFullMTC()
    now += tick
    prepareMidiTimeCode()
    mach_wait_until(now - startOffset)
    if self.playing {
      run()
    }
  }

  private func prepareMidiTimeCode() {
    let frameRateBinary = framerate.binary
    var frameByte: UInt8 = 0
    let standardByte: UInt8 = 0xF1
    // Calculate the timestamp of the next messages
    let ms = (now-startTime) / 1000000
    let frames = (ms / 40) % 25
    let seconds = (ms / 1000) % 60
    let minutes = ((ms / 1000) / 60) % 60
    let hours = ((ms / 1000) / 60 / 60) % 60

    // Update time code label
    setDisplay(String(format: "%02d:%02d:%02d:%02d", hours, minutes, seconds, frames))

    // Split and send the timestamp in 8 quarterframe messages
    for quarterFrame in 0...7 {
      switch quarterFrame {
      case 0: // Frames
        frameByte = convertToByte(quarterFrame, hexValue: frames.lowNibble())
      case 1:
        frameByte = convertToByte(quarterFrame, hexValue: frames.highNibble())
      case 2: // Seconds
        frameByte = convertToByte(quarterFrame, hexValue: seconds.lowNibble())
      case 3:
        frameByte = convertToByte(quarterFrame, hexValue: seconds.highNibble())
      case 4: // Minutes
        frameByte = convertToByte(quarterFrame, hexValue: minutes.lowNibble())
      case 5:
        frameByte = convertToByte(quarterFrame, hexValue: minutes.highNibble())
      case 6: // Hours and framerate
        frameByte = convertToByte(quarterFrame, hexValue: hours.lowNibble())
      case 7:
        let binary = "0\(frameRateBinary)\(hours.highNibble())"
        let number = "\(strtoul(binary, nil, 2))"
        frameByte = convertToByte(quarterFrame, hexValue: number)
      default: // Not used
        frameByte = UInt8(0)
      }
      quarterFrameMessages[quarterFrame] = [standardByte, frameByte]
    }
  }

  // Double pushing the stop button will reset the timer to zero
  private var numberOfStopPushes = 0
  func stop() {
    playing = false
    numberOfStopPushes++
    if numberOfStopPushes == 2 {
      now = 0
      startOffset = 0
      numberOfStopPushes = 0
      setDisplay("00:00:00:00")
    } else {
      startOffset += mach_absolute_time() - startTime
    }
  }
}
