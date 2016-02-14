//
//  ViewController.swift
//  Socket-Sync-Mac
//
//  Created by Anders Bech Mellson on 06/02/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import Cocoa

class MacViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  @IBOutlet var textField: NSTextField!
  @IBOutlet var songPopup: NSPopUpButton!

  @IBOutlet var jumpBackButton: NSButton!
  @IBOutlet var stopButton: NSButton!
  @IBOutlet var playButton: NSButton!
  @IBOutlet var jumpForwardButton: NSButton!

  @IBOutlet var nodeTableView: NSTableView!

  // Needs to be here for App Nap to disable
  var activity: NSObjectProtocol?

  func setDisplay(string: String) {
    textField.stringValue = string
  }

  func setSong(title: String) {
    songPopup.selectItemWithTitle(title)
  }

  let node = Node()
  override func viewDidLoad() {
    super.viewDidLoad()

    // Disable App Nap
    activity = NSProcessInfo().beginActivityWithOptions(NSActivityOptions.UserInitiated, reason: "Realtime Application")

    // Node Info Table View
    nodeTableView.setDelegate(self)
    nodeTableView.setDataSource(self)
    node.setNodeInfo(updateTableView)

    node.enablePlayerControls = enablePlayerControls
    node.linearResultsWriter = linearResultsWriter
    node.setSong = setSong
    node.setDisplay = setDisplay
    songPopup.addItemsWithTitles(node.songs)
    node.currentSong = node.songs.first!
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    Async.userInitiated {
      if is64bit {
        print("64 bit")
        if !isConnectedToNetwork() {
          self.setDisplay("No network, please connect and relaunch!")
          self.enablePlayerControls(false)
        } else {
          self.node.startNode()
          self.node.commander.calibrateOffset()
        }
      } else {
        print("32 bit")
        Async.main {
          self.node.setDisplay!("Sorry this app requires a 64bit device")
          self.enablePlayerControls(false)
        }
      }
    }
  }

  func enablePlayerControls(enable: Bool) {
    self.jumpBackButton.enabled = enable
    self.stopButton.enabled = enable
    self.playButton.enabled = enable
    self.jumpForwardButton.enabled = enable
    self.songPopup.enabled = enable
  }

  @IBAction func songChanged(sender: NSPopUpButton) {
    let song = sender.titleOfSelectedItem!
    node.commander.setSong(song)
    node.tcpCommunicator.sendSetSongCommand(song)
  }

  @IBAction func stopMusic(sender: NSButton) {
    node.tcpCommunicator.sendStopCommand()
    node.commander.stopMusic()
  }

  @IBAction func playMusic(sender: NSButton) {
    switch node.currentSong {
    case "test1":
      node.commander.runShortTest()
    default:
      node.commander.play()
    }
  }

  @IBAction func jumpBack(sender: NSButton) {
    node.commander.jumpBack()
  }

  @IBAction func jumpForward(sender: NSButton) {
    node.commander.jumpForward()
  }

  var linearCounter = 1
  func linearResultsWriter(xs: [Double], ys: [Double], precision: String) {
    var result = "\(precision)\n"
    var index = 0
    for x in xs {
      let y = ys[index++]
      result += "\(x/NSEC_PER_SEC.double) \(y/NSEC_PER_SEC.double)\n"
    }

    let file = "linearData\(linearCounter++).txt" // Write to the file linearData on the desktop
    if let dirs : [String] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DesktopDirectory, NSSearchPathDomainMask.AllDomainsMask, true) {
      let dir = dirs[0] // Home
      let path = dir.stringByAppendingPathComponent(file);
      do {
        try result.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
      } catch _ {
      };
    } else {
      print("huh?")
    }
  }

  // TableView
  var dataArray: [NSDictionary] = []
  func numberOfRowsInTableView(tableView: NSTableView) -> Int
  {
    let numberOfRows: Int = getDataArray().count
    return numberOfRows
  }

  func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject?
  {
    let newString: (AnyObject?) = getDataArray().objectAtIndex(row).objectForKey(tableColumn!.identifier)
    return newString;
  }

  func getDataArray () -> NSArray {
    return dataArray
  }

  func updateTableView(info: (String,String)) {
    let elem = ["NodeName": info.0, "NodeInfo": info.1]
    var replacedExisting = false
    var index = 0
    for dict in dataArray {
      if (dict.valueForKey("NodeName") as! String) == info.0 {
        dataArray[index] = elem
        replacedExisting = true
      }
      index++
    }
    if !replacedExisting {
      dataArray.append(elem)
    }
    nodeTableView.reloadData()
  }
}

