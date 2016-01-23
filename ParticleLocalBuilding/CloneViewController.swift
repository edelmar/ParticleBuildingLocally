//
//  CloneViewController.swift
//  ParticleLocalBuild
//
//  Created by Eric G. DelMar on 1/20/16.
//  Copyright © 2016 Eric G. DelMar. All rights reserved.
//

import Cocoa

class CloneViewController: NSViewController {

    @IBOutlet var cloneSourceRadios: NSMatrix!
    @IBOutlet var baseFolderField: NSTextField!
    @IBOutlet var appsParentFolderField: NSTextField!
    @IBOutlet var appFolderField: NSTextField!
    @IBOutlet var button: NSButton!
    @IBOutlet var tv: NSTextView!
    @IBOutlet var scroller: NSScrollView!
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var cloneTask: NSTask!
    var checkoutTask: NSTask!
    var cloneType: String!
    var cloneObserver: AnyObject!
    var checkoutObserver: AnyObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"taskDidTerminate:", name:NSTaskDidTerminateNotification, object:nil)
        defaults.registerDefaults(["baseFolderPath": "", "appsParentPath": "", "appFolderPath": "", "cloneType": ""])
        baseFolderField.stringValue = defaults.stringForKey("baseFolderPath")!
        appsParentFolderField.stringValue = defaults.stringForKey("appsParentPath")!
        appFolderField.stringValue = defaults.stringForKey("appFolderPath")!
        defaults.synchronize()
        if cloneSourceRadios.selectedRow == 0 {
            button.title = "Go To Build Controller"
        }else{
            button.title = "Clone Repo Then Go To Build Controller"
        }
    }
    
    
    
    @IBAction func radiosWereChanged(sender: NSMatrix) {
        if sender.selectedRow == 0 {
            button.title = "Go To Build Controller"
        }else{
            button.title = "Clone Repo Then Go To Build Controller"
        }
    }
    
    
    @IBAction func buttonPressed(sender: NSButton) {
        cloneType = defaults.stringForKey("cloneType")!
        if cloneSourceRadios.selectedRow != 0 {
            cloneType = "PARTICLE_DEVELOP=1"
            sender.enabled = false;
            let fm = NSFileManager.defaultManager()
            fm.changeCurrentDirectoryPath(baseFolderField.stringValue)
            cloneTask = NSTask()
            cloneTask.launchPath = "/usr/bin/git"
            cloneTask.arguments = ["clone", "--progress", "https://github.com/spark/firmware.git"]
            scroller.hidden = false
            cloneObserver = cloneTask.pipeErrorTo(tv)
            cloneTask.launch()
        }else{
            performSegueWithIdentifier("GoToBuild", sender: nil)
        }
        
    }
    
    
    func taskDidTerminate(notification: NSNotification) {
        tv.append("\n\n***************** Cloning Finished ********************\n\n")
        
        if cloneSourceRadios.selectedRow == 1 && notification.object as? NSTask == cloneTask {
            cloneType = ""
            let fm = NSFileManager.defaultManager()
            fm.changeCurrentDirectoryPath(baseFolderField.stringValue + "/firmware")
            checkoutTask = NSTask()
            checkoutTask.launchPath = "/usr/bin/git"
            checkoutTask.arguments = ["checkout", "latest"]
            checkoutObserver = checkoutTask.pipeErrorTo(tv)
            checkoutTask.launch()
        }else if notification.object as? NSTask == checkoutTask || cloneSourceRadios.selectedRow == 2 {
            let delay = cloneSourceRadios.selectedRow == 2 ? 0 : 1.5 as NSTimeInterval
            performSelector("invokeSegue", withObject: nil, afterDelay: delay)
        }
    }
    
    
    
    func invokeSegue() {
        scroller.hidden = true
        performSegueWithIdentifier("GoToBuild", sender: nil)
    }
    
    
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if cloneObserver != nil {
            NSNotificationCenter.defaultCenter().removeObserver(cloneObserver)
        }
        if checkoutObserver != nil {
            NSNotificationCenter.defaultCenter().removeObserver(checkoutObserver)
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
        button.enabled = true
        defaults.setValue(cloneType, forKey: "cloneType")
        defaults.setValue(baseFolderField.stringValue, forKey: "baseFolderPath")
        defaults.setValue(appsParentFolderField.stringValue, forKey: "appsParentPath")
        defaults.setValue(appFolderField.stringValue, forKey: "appFolderPath")
        defaults.synchronize()
        
        let destVC = segue.destinationController as! BuildViewController
        destVC.firmwareSource = cloneSourceRadios.selectedRow
        destVC.baseFolderPath = baseFolderField.stringValue
        destVC.allAppsFolderPath = appsParentFolderField.stringValue
        destVC.appFolder = appFolderField.stringValue
        destVC.cloneType = cloneType
    }
    
    
}





