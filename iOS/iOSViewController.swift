//
//  ViewController.swift
//  Socket-Sync
//
//  Created by Anders Bech Mellson on 06/02/15.
//  Copyright (c) 2015 dk.mellson. All rights reserved.
//

import UIKit

class iOSViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDelegate, UITableViewDataSource {
  @IBOutlet var timeLabel: UILabel!
  @IBOutlet var songPicker: UIPickerView!
  @IBOutlet var jumpBackButton: UIButton!
  @IBOutlet var stopButton: UIButton!
  @IBOutlet var playButton: UIButton!
  @IBOutlet var jumpForwardButton: UIButton!
  @IBOutlet var nodeTableView: UITableView!

  let node = Node()
  override func viewDidLoad() {
    super.viewDidLoad()

    songPicker.dataSource = self
    songPicker.delegate = self

    // Turn off sleep mode
    UIApplication.sharedApplication().idleTimerDisabled = true

    // Node Info Table View
    nodeTableView.delegate = self
    nodeTableView.dataSource = self
    nodeTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    node.setNodeInfo(updateTableView)

    node.enablePlayerControls = enablePlayerControls
    node.setSong = setSong
    node.setDisplay = setDisplay
    node.currentSong = node.songs.first!
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    Async.userInitiated {
      if is64bit {
        print("64 bit")
        if !isConnectedToNetwork() {
          self.setDisplay("No network, relaunch!")
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
    self.songPicker.hidden = !enable
  }

  func setSong(song: String) {
    let i = node.songs.indexOf(song)
    songPicker.selectRow(i!, inComponent: 0, animated: true)
  }

  func setDisplay(string: String) {
    timeLabel.text = string
  }

  @IBAction func jumpBack() {
    node.commander.jumpBack()
  }

  @IBAction func stop() {
    node.tcpCommunicator.sendStopCommand()
    node.commander.stopMusic()
  }


  @IBAction func play() {
    node.commander.play()
  }

  @IBAction func jumpForward() {
    node.commander.jumpForward()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    print("received memory warning")
    // Dispose of any resources that can be recreated.
  }

  func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return node.songs.count
  }

  func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return node.songs[row]
  }

  func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    let song = node.songs[row]
    node.commander.setSong(song)
    node.tcpCommunicator.sendSetSongCommand(song)
  }

  // TableView
  var dataArray: [NSDictionary] = []
  func getDataArray () -> NSArray {
    return dataArray
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return getDataArray().count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

    let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell

    let x: NSDictionary = getDataArray().objectAtIndex(indexPath.row) as! NSDictionary
    let k = "\(x[nodeName]!) - \(x[nodeInfo]!)"
    cell.textLabel?.text = k

    return cell

  }

  let nodeName = "NodeName"
  let nodeInfo = "NodeInfo"
  func updateTableView(info: (String,String)) {
    let elem = [nodeName: info.0, nodeInfo: info.1]
    var replacedExisting = false
    var index = 0
    for dict in dataArray {
      if (dict.valueForKey(nodeName) as! String) == info.0 {
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

