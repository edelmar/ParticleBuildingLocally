//
//  BuildViewController.swift
//  ParticleLocalBuild
//
//  Created by Eric G. DelMar on 1/20/16.
//  Copyright © 2016 Eric G. DelMar. All rights reserved.
//

import Cocoa

class BuildViewController: NSViewController, ORSSerialPortDelegate, NSUserNotificationCenterDelegate {

    @IBOutlet var tv: NSTextView!
    @IBOutlet var buildTypeChooser: NSPopUpButton!
    @IBOutlet var deviceChooser: NSPopUpButton!
    @IBOutlet var checkBox: NSButton!
    @IBOutlet var openCloseButton: NSButton!
    @IBOutlet var portChooser: NSPopUpButton!
    
    let fm = NSFileManager.defaultManager()
    var observer: AnyObject!
    var baseFolderPath: String!
    var allAppsFolderPath: String!
    var appFolder: String!
    var firmwareSource: Int!
    var deviceSource: String!
    var cloneType: String!
    var serialPortManager = ORSSerialPortManager.sharedSerialPortManager()
    var serialPort: ORSSerialPort? {
        didSet {
            oldValue?.close()
            oldValue?.delegate = nil
            if  let port = serialPort {
                port.delegate = self
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        if firmwareSource == 0 {
            buildTypeChooser.selectItemWithTitle("Incremental build of application firmware only")
        }else{
            buildTypeChooser.selectItemWithTitle("Complete build of system and app firmware")
        }
        
        deviceSource = deviceChooser.titleOfSelectedItem
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "serialPortsWereConnected:", name: ORSSerialPortsWereConnectedNotification, object: nil)
        nc.addObserver(self, selector: "serialPortsWereDisconnected:", name: ORSSerialPortsWereDisconnectedNotification, object: nil)
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
    }
    
    
    deinit {
        print("deinit")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    

    
    
    @IBAction func openOrClosePort(sender: AnyObject) {
        if let port = self.serialPort {
            if (port.open) {
                port.close()
            } else {
                port.open()
                tv.textStorage?.mutableString.setString("");
            }
        }
    }
    
    
    
    @IBAction func actionButtonPressed(sender: NSButton) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"taskDidTerminate:", name:NSTaskDidTerminateNotification, object:nil)
        let flash = sender.title == "Build" ?  "" : "program-dfu"
        let device = deviceChooser.titleOfSelectedItem?.lowercaseString
        let cleanString = buildTypeChooser.indexOfSelectedItem == 0 ? "clean" : "" // first menu item is for complete rebuild, the other two options are for incremental builds
        let argString = "make PLATFORM=\(device!) \(cleanString) all \(cloneType) APPDIR=\(allAppsFolderPath)/\(appFolder) \(flash)"
        
        let firmwareSubFolder = buildTypeChooser.indexOfSelectedItem == 2 ? "main" : "modules" // the choice at index 2, application only, should run from 'main', the other choices rebuild system firmaware, so run from 'modules'
        fm.changeCurrentDirectoryPath(baseFolderPath + "/firmware/\(firmwareSubFolder)")
        
        let task = NSTask()
        task.launchPath = "/bin/bash"
        task.arguments = ["-l", "-c", argString]
        observer = task.pipeOutputTo(self.tv)
        task.launch()
    }
    
    
    func taskDidTerminate(notification: NSNotification) {
        tv.append("\n\n******************* Build Finished **********************\n\n\n")
        NSNotificationCenter.defaultCenter().removeObserver(observer)
        buildTypeChooser.selectItemWithTitle("Incremental build of application firmware only")
    }
    
        
    
    // MARK: - ORSSerialPortDelegate
    
    func serialPortWasOpened(serialPort: ORSSerialPort) {
        self.openCloseButton.title = "Close"
    }
    
    func serialPortWasClosed(serialPort: ORSSerialPort) {
        self.openCloseButton.title = "Open"
    }
    
    func serialPort(serialPort: ORSSerialPort, didReceiveData data: NSData) {
        if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
            tv.textStorage?.mutableString.appendString(string as String)
            tv.needsDisplay = true
        }
    }
    
    func serialPortWasRemovedFromSystem(serialPort: ORSSerialPort) {
        self.serialPort = nil
        self.openCloseButton.title = "Open"
    }
    
    func serialPort(serialPort: ORSSerialPort, didEncounterError error: NSError) {
        print("SerialPort \(serialPort) encountered an error: \(error)")
    }
    
    // MARK: - NSUserNotifcationCenterDelegate
    
    func userNotificationCenter(center: NSUserNotificationCenter, didDeliverNotification notification: NSUserNotification) {
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3.0 * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
            center.removeDeliveredNotification(notification)
        }
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
    
    // MARK: - Notifications
    
    func serialPortsWereConnected(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let connectedPorts = userInfo[ORSConnectedSerialPortsKey] as! [ORSSerialPort]
            print("Ports were connected: \(connectedPorts)")
            self.postUserNotificationForConnectedPorts(connectedPorts)
        }
    }
    
    
    func serialPortsWereDisconnected(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let disconnectedPorts: [ORSSerialPort] = userInfo[ORSDisconnectedSerialPortsKey] as! [ORSSerialPort]
            print("Ports were disconnected: \(disconnectedPorts)")
            self.postUserNotificationForDisconnectedPorts(disconnectedPorts)
        }
    }
    
    
    
    func postUserNotificationForConnectedPorts(connectedPorts: [ORSSerialPort]) {
        let unc = NSUserNotificationCenter.defaultUserNotificationCenter()
        for port in connectedPorts {
            let userNote = NSUserNotification()
            userNote.title = NSLocalizedString("Serial Port Connected", comment: "Serial Port Connected")
            userNote.informativeText = "Serial Port \(port.name) was connected to your Mac."
            userNote.soundName = nil;
            unc.deliverNotification(userNote)
            if checkBox.state == NSOnState {
                performSelector("openJustAddedPort:", withObject: port, afterDelay: 0.5)
            }
        }
    }
    
    
    func openJustAddedPort(port: ORSSerialPort) {
        tv.textStorage?.setAttributedString(NSAttributedString(string: ""))
        portChooser.selectItemWithTitle(port.name)
        self.serialPort = port
        serialPort!.open()
    }
    
    
    func postUserNotificationForDisconnectedPorts(disconnectedPorts: [ORSSerialPort]) {
        let unc = NSUserNotificationCenter.defaultUserNotificationCenter()
        for port in disconnectedPorts {
            let userNote = NSUserNotification()
            userNote.title = NSLocalizedString("Serial Port Disconnected", comment: "Serial Port Disconnected")
            userNote.informativeText = "Serial Port \(port.name) was disconnected from your Mac."
            userNote.soundName = nil;
            unc.deliverNotification(userNote)
        }
    }

    
}
