//
//  Extensions.swift
//  blah11232
//
//  Created by Eric G. DelMar on 1/19/16.
//  Copyright © 2016 Eric G. DelMar. All rights reserved.
//

import Foundation
import Cocoa


extension NSTextView {
    func append(string: String) {
        self.textStorage?.appendAttributedString(NSAttributedString(string: string))
        self.scrollToEndOfDocument(nil)
    }
}


extension NSTask {
    
    func pipeOutputTo(logger: AnyObject) -> AnyObject {
        return pipeOutput(logger, type: "Output")
    }
    
    
    func pipeErrorTo(logger: AnyObject) -> AnyObject {
        return pipeOutput(logger, type: "Error")
    }
    
    
    private func pipeOutput(logger: AnyObject, type: String) -> AnyObject {
        let pipe = NSPipe()
        if type == "Error" {
            self.standardError = pipe
        }else{
            self.standardOutput = pipe
        }
        
        
        let stdoutHandle = pipe.fileHandleForReading
        stdoutHandle.waitForDataInBackgroundAndNotify()
        let observer = NSNotificationCenter.defaultCenter().addObserverForName(NSFileHandleDataAvailableNotification, object: stdoutHandle, queue: nil) { _ in
            let dataRead = stdoutHandle.availableData
            let stringRead = NSString(data: dataRead, encoding: NSUTF8StringEncoding)
            logger.append(stringRead as! String)
            if stringRead!.length > 0 {
                stdoutHandle.waitForDataInBackgroundAndNotify()
            }
        }
        return observer
    }
    
    
}
