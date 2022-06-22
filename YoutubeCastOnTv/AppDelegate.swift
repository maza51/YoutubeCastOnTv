//
//  AppDelegate.swift
//  YoutubeCastOnTv
//
//  Created by kirill reutov on 27.03.2018.
//  Copyright © 2018 kirill reutov. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let popover = NSPopover()
    var eventMonitor: EventMonitor?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let icon = NSImage(named:NSImage.Name("icon_status"))
        icon?.isTemplate = true
        statusItem.button?.image = icon
        statusItem.button?.action = #selector(togglePopover(_:))
        
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "ViewController")
        if let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ViewController {
            popover.contentViewController = viewcontroller
        }
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                self?.popover.performClose(event)
            }
        }
        eventMonitor?.start()
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

