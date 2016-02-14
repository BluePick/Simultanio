//
//  Message.swift
//  Socket-Sync
//
//  Created by Anders Bech Mellson on 19/02/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Foundation

enum MessageType: Int {
  case Play
  case Stop
  case Jump
  case Pulse
  case SetSong
  case ExecutionTime
  case PulseObservation

  var description : String {
    switch self {
    case .Play: return "Play"
    case .Stop: return "Stop"
    case .Jump: return "Jump"
    case .Pulse: return "Pulse"
    case .SetSong: return "SetSong"
    case .ExecutionTime: return "ExecutionTime"
    case .PulseObservation: return "PulseObservation"
    }
  }
}

/** @objc(XRObjectAllocRun) added to make the fully qualified classname of UdpMessage
*  be the same across iOS and OS X.
*  http://stackoverflow.com/questions/27974959/how-to-change-the-namespace-of-a-swift-class
**/
@objc(XRObjectAllocRun) class Message: NSObject, NSCoding
{
  let type: MessageType
  let pulseId: String
  let observationTime: Double
  let executionTime: UInt64
  let deviceStartTime: UInt64
  let jumpTime: Double
  let deviceName: String
  let songName: String

  init(type: MessageType, pulseId: String, observationTime: Double, executionTime: UInt64, deviceStartTime: UInt64, jumpTime: Double, deviceName: String, songName: String) {
    self.type = type
    self.pulseId = pulseId
    self.observationTime = observationTime
    self.executionTime = executionTime
    self.deviceStartTime = deviceStartTime
    self.jumpTime = jumpTime
    self.deviceName = deviceName
    self.songName = songName
  }

  convenience init(type: MessageType) {
    self.init(type: type, pulseId: "", observationTime: 0, executionTime: 0, deviceStartTime: 0, jumpTime: 0, deviceName: "", songName: "")
  }

  convenience init(type: MessageType, deviceName: String) {
    self.init(type: type, pulseId: "", observationTime: 0, executionTime: 0, deviceStartTime: 0, jumpTime: 0, deviceName: deviceName, songName: "")
  }

  convenience init(type: MessageType, deviceStartTime: UInt64, deviceName: String) {
    self.init(type: type, pulseId: "", observationTime: 0, executionTime: 0, deviceStartTime: deviceStartTime, jumpTime: 0, deviceName: deviceName, songName: "")
  }

  convenience init(type: MessageType, pulseId: String, deviceName: String, deviceStartTime: UInt64) {
    self.init(type: type, pulseId: pulseId, observationTime: 0, executionTime: 0, deviceStartTime: deviceStartTime, jumpTime: 0, deviceName: deviceName, songName: "")
  }

  convenience init(type: MessageType, executionTime: UInt64, songName: String, deviceName: String) {
    self.init(type: type, pulseId: "", observationTime: 0, executionTime: executionTime, deviceStartTime: 0, jumpTime: 0, deviceName: deviceName, songName: songName)
  }

  convenience init(type: MessageType, pulseId: String, observationTime: Double, deviceName: String) {
    self.init(type: type, pulseId: pulseId, observationTime: observationTime, executionTime: 0, deviceStartTime: 0, jumpTime: 0, deviceName: deviceName, songName: "")
  }

  convenience init(type: MessageType, executionTime: UInt64, jumpTime: Double, deviceName: String) {
    self.init(type: type, pulseId: "", observationTime: 0, executionTime: executionTime, deviceStartTime: 0, jumpTime: jumpTime, deviceName: deviceName, songName: "")
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeInteger(type.rawValue, forKey: "type")
    aCoder.encodeObject(pulseId, forKey: "pulseId")
    aCoder.encodeDouble(observationTime, forKey: "observationTime")
    aCoder.encodeDouble(jumpTime, forKey: "jumpTime")
    aCoder.encodeInt64(Int64(executionTime), forKey: "executionTime")
    aCoder.encodeInt64(Int64(deviceStartTime), forKey: "deviceStartTime")
    aCoder.encodeObject(deviceName, forKey: "deviceName")
    aCoder.encodeObject(songName, forKey: "songName")
  }

  required init?(coder aDecoder: NSCoder) {
    self.type = MessageType(rawValue: aDecoder.decodeIntegerForKey("type"))!
    self.pulseId = aDecoder.decodeObjectForKey("pulseId") as! String
    self.observationTime = aDecoder.decodeDoubleForKey("observationTime")
    self.jumpTime = aDecoder.decodeDoubleForKey("jumpTime")
    self.executionTime = UInt64(aDecoder.decodeInt64ForKey("executionTime"))
    self.deviceStartTime = UInt64(aDecoder.decodeInt64ForKey("deviceStartTime"))
    self.deviceName = aDecoder.decodeObjectForKey("deviceName") as! String
    self.songName = aDecoder.decodeObjectForKey("songName") as! String
    super.init()
  }
}

func asData(msg: Message) -> NSData {
  return NSKeyedArchiver.archivedDataWithRootObject(msg)
}

func fromData(data: NSData) -> Message {
  return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! Message
}

func pulse(deviceName: String, deviceStartTime: UInt64) -> NSData {
  return asData(Message(type: .Pulse, pulseId: NSUUID().UUIDString, deviceName: deviceName, deviceStartTime: deviceStartTime))
}

func pulseObservation(pulseId: String, observationTime: Double, deviceName: String) -> NSData {
  return asData(Message(type: .PulseObservation, pulseId: pulseId, observationTime: observationTime, deviceName: deviceName))
}

func getStopCommand() -> NSData {
  return asData(Message(type: .Stop))
}

func getPlayCommand(executionTime: UInt64, songName: String, deviceName: String) -> NSData {
  return asData(Message(type: .Play, executionTime: executionTime, songName: songName, deviceName: deviceName))
}

func getJumpCommand(executionTime: UInt64, jumpTime: Double, deviceName: String) -> NSData {
  return asData(Message(type: .Jump, executionTime: executionTime, jumpTime: jumpTime, deviceName: deviceName))
}

func getSetSongCommand(song: String) -> NSData {
  return asData(Message(type: .SetSong, deviceName: song))
}