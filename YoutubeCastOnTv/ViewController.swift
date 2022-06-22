//
//  ViewController.swift
//  YoutubeCastOnTv
//
//  Created by kirill reutov on 27.03.2018.
//  Copyright © 2018 kirill reutov. All rights reserved.
//

import Cocoa
import SWXMLHash

class ViewController: NSViewController, FinderDelegate {
    
    @IBOutlet weak var imageButton: NSButton!
    @IBOutlet weak var slider: NSSlider!
    @IBOutlet weak var timeReal: NSTextField!
    @IBOutlet weak var timeDuration: NSTextField!
    @IBOutlet weak var buttonPlay: NSButton!
    @IBOutlet weak var labelInfo: NSTextField!
    
    var deviceFinder: UPnPDeviceFinder!
    var device: UPnPDevice!
    
    var timer = Timer()
    var timerNotify = Timer()
    
    var videoId: String!
    var videoIdCur: String!
    
    var isShown = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let trackArea = NSTrackingArea(rect: imageButton.bounds, options: [.activeInActiveApp,.mouseEnteredAndExited], owner: self, userInfo: nil)
        imageButton.addTrackingArea(trackArea)
        
        deviceFinder = UPnPDeviceFinder()
        deviceFinder.delegate = self
        imageButton.alphaValue = 0.8
    }
    
    override func viewWillAppear() {
        isShown = true
        device = nil
        deviceFinder.find()
    }
    
    override func viewWillDisappear() {
        isShown = false
    }
    
    override func mouseEntered(with event: NSEvent) {
        imageButton.alphaValue = 1
    }
    
    override func mouseExited(with event: NSEvent) {
        if imageButton.image != nil {
            imageButton.alphaValue = 0.8
        }
    }
    
    @IBAction func imageClicked(_ sender: NSButton) {
        let pasteboard = NSPasteboard.general
        let objects = pasteboard.readObjects(forClasses: [NSString.self], options: [:]) as! [String]
        
        guard let string = objects.first else {
            print("Bad url..")
            addNotify(string: "Bad url..")
            return
        }
        
        let nsString = string as NSString
        if nsString.contains("img.youtube.com/vi") {
            print("Bad url..")
            addNotify(string: "Bad url..")
            return
        }
        
        let validRegex = "(?:youtube\\.com/(?:[^/]+/.+/|(?:v|e(?:mbed)?)/|.*[?&]v=)|youtu\\.be/)([^\"&?/ ]{11}).*"
        let regex = try! NSRegularExpression(pattern: validRegex, options: [])
        let result = regex.firstMatch(in: nsString as String, options: [], range: NSMakeRange(0, nsString.length))
        
        if (result != nil) {
            let videoIdTmp = nsString.substring(with: (result?.range(at: 1))!)
            print(videoIdTmp)
            let url:NSURL = NSURL(string: "http://img.youtube.com/vi/\(videoIdTmp)/mqdefault.jpg")!
            let data:NSData = NSData(contentsOf: url as URL)!
            
            imageButton.image = NSImage(data: data as Data)
            
            videoId = videoIdTmp
        }
        else {
            print("Bad url..")
            addNotify(string: "Bad url..")
        }
    }
    
    @IBAction func playClicked(_ sender: NSButton) {
        if self.device == nil {
            print("Device not found")
            addNotify(string: "Device\nnot found")
            return
        }
        
        updateDeviceInfo()
        
        if device.currentTransportState == "PLAYING" {
            sender.image = NSImage(named: NSImage.Name(rawValue: "qwe"))!
            UPnPActions.pause(url: device.controlUrl)
            return
        }
        
        if device.currentTransportState == "NO_MEDIA_PRESENT" && videoId != nil || videoId != nil && videoId != videoIdCur {
            UPnPActions.stop(url: device.controlUrl)
            
            var t = ""
            if let id = videoId {
                //t = Test.go(id: id)
                t = YoutubeParse.go(id: id)
                if t.contains("quality") {
                    addNotify(string: t)
                    return
                }
                //print("=> test ->>>> \n\(t)")
            }
            t = t.replacingOccurrences(of: "\n", with: "")
            
            sender.image = NSImage(named: NSImage.Name(rawValue: "icon_pause"))!
            
            UPnPActions.setAvTransportUrl(url: device.controlUrl, urlVideo: t)
            UPnPActions.play(url: device.controlUrl)
            
            videoIdCur = videoId
        }
        else {
            sender.image = NSImage(named: NSImage.Name(rawValue: "icon_pause"))!
            UPnPActions.play(url: device.controlUrl)
        }
        
        self.timer.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateDeviceInfo), userInfo: nil, repeats: true)
    }
    
    @IBAction func sliderValueChanged(_ sender: NSSlider) {
        if self.device == nil {
            print("Device not found")
            addNotify(string: "Device\nnot found")
            return
        }
        
        
        UPnPActions.seek(url: device.controlUrl, time: getTimeOfSeconds(sec: sender.floatValue))
    }
    
    @IBAction func backClicked(_ sender: NSButton) {
        if self.device == nil {
            print("Device not found")
            addNotify(string: "Device\nnot found")
            return
        }
        
        
        let s = slider.floatValue - 10
        UPnPActions.seek(url: device.controlUrl, time: getTimeOfSeconds(sec: s))
    }
    
    @IBAction func forwardClicked(_ sender: NSButton) {
        if self.device == nil {
            print("Device not found")
            addNotify(string: "Device\nnot found")
            return
        }
        
        
        let s = slider.floatValue + 10
        UPnPActions.seek(url: device.controlUrl, time: getTimeOfSeconds(sec: s))
    }
    
    @IBAction func stopClicked(_ sender: NSButton) {
        if self.device == nil {
            print("Device not found")
            addNotify(string: "Device\nnot found")
            return
        }
        
        
        UPnPActions.stop(url: self.device.controlUrl)
    }
    
    @IBAction func settingClicked(_ sender: NSButton) {
        NSApplication.shared.terminate(self)
        
        //http://getfbstuff.com/download-vimeo-video
        //UPnPActions.setAvTransportUrl(url: device.controlUrl, urlVideo: "https://gcs-vimeo.akamaized.net/exp=1523124327~acl=%2A%2F966918749.mp4%2A~hmac=bfd4e66d079119010938eef7f06b41214b15c4a027584e9d72f834ef70a38bd8/vimeo-prod-skyfire-std-us/01/2470/10/262351620/966918749.mp4")
        
        //UPnPActions.play(url: device.controlUrl)
    }
    
    @objc func updateDeviceInfo() {
        if device == nil {
            return
        }
        
        if !isShown {
            return
        }
        
        var xml = SWXMLHash.parse(UPnPActions.getTransportInfo(url: device.controlUrl))
        if let state = xml["s:Envelope"]["s:Body"]["u:GetTransportInfoResponse"]["CurrentTransportState"].element?.text {
            self.device.currentTransportState = state
        }
        
        xml = SWXMLHash.parse(UPnPActions.getPositionInfo(url: self.device.controlUrl))
        if let duration = xml["s:Envelope"]["s:Body"]["u:GetPositionInfoResponse"]["TrackDuration"].element?.text {
            self.device.trackDuration = duration
        }
        if let time = xml["s:Envelope"]["s:Body"]["u:GetPositionInfoResponse"]["RelTime"].element?.text {
            self.device.relTime = time
        }
        
        if device.currentTransportState != "PLAYING" && device.currentTransportState != "TRANSITIONING" {
            timer.invalidate()
            buttonPlay.image = NSImage(named: NSImage.Name(rawValue: "qwe"))!
        }
        
        updateTimeline()
    }
    
    func updateTimeline() {
        var tmp = self.device.relTime as NSString
        
        var realSec = Int(tmp.substring(with: NSRange(location: 0, length: 1)))! * 60 * 60
        realSec += Int(tmp.substring(with: NSRange(location: 2, length: 2)))! * 60
        realSec += Int(tmp.substring(with: NSRange(location: 5, length: 2)))!
        
        tmp = self.device.trackDuration as NSString
        
        var durationSec = Int(tmp.substring(with: NSRange(location: 0, length: 1)))! * 60 * 60
        durationSec += Int(tmp.substring(with: NSRange(location: 2, length: 2)))! * 60
        durationSec += Int(tmp.substring(with: NSRange(location: 5, length: 2)))!
        
        timeReal.stringValue = self.device.relTime
        timeDuration.stringValue = self.device.trackDuration
        slider.minValue = 0
        slider.maxValue = Double(durationSec)
        slider.floatValue = Float(realSec)
    }
    
    func addNotify(string: String) {
        labelInfo.stringValue = string
        
        timerNotify.invalidate()
        timerNotify = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.removeNotify), userInfo: nil, repeats: false)
    }
    
    @objc func removeNotify() {
        timerNotify.invalidate()
        labelInfo.stringValue = ""
    }
    
    func getTimeOfSeconds(sec: Float) -> String {
        let f = Int(floor(sec))
        let h = f / 60 / 60
        let m = (f - (h * 60 * 60)) / 60
        let s = (f - (h * 60 * 60)) - (m * 60)
        
        return "\(h):\(m < 10 ? "0\(m)" : "\(m)"):\(s < 10 ? "0\(s)" : "\(s)")"
    }
    
    func foundDevice(device: UPnPDevice) {
        self.device = device
        //updateDeviceInfo()
        print("Device found")
    }
}
