//
//  UPnPDeviceFinder.swift
//  YoutubeCastOnTv
//
//  Created by kirill reutov on 29.03.2018.
//  Copyright © 2018 kirill reutov. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public struct UPnPDevice {
    var ip: String
    var port: String
    var controlUrl: URL
    var trackDuration: String
    var relTime: String
    var currentTransportState: String
}

public protocol FinderDelegate: class {
    func foundDevice(device: UPnPDevice)
}

class UPnPDeviceFinder: NSObject {
    private var udpSocket: GCDAsyncUdpSocket!
    private let host: String = "239.255.255.250"
    private let port: UInt16 = 1900
    private let searchMsg: String = "M-SEARCH * HTTP/1.1\r\nMAN: \"ssdp:discover\"\r\nMX: 5\nHOST: 239.255.255.250:1900\r\nST: urn:schemas-upnp-org:service:AVTransport:1\r\n\r\n"
    
    public weak var delegate: FinderDelegate?
    
    override init() {
        super.init()
        
        udpSocket = GCDAsyncUdpSocket.init(delegate: self as GCDAsyncUdpSocketDelegate, delegateQueue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        
        do {
            try udpSocket.enableReusePort(true)
        } catch {
            print("error in enableReusePort")
        }
        do {
            try udpSocket.beginReceiving()
        } catch {
            print("error in beginReceiving")
        }
    }
    
    public func find() {
        let data: Data = searchMsg.data(using: .utf8)!
        udpSocket.send(data, toHost: host, port: port, withTimeout: 100, tag: 100)
    }
}

extension UPnPDeviceFinder: GCDAsyncUdpSocketDelegate {
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        let msg: NSString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)!
        let validRegex = "LOCATION: (http://([0-999]+.[0-999]+.[0-999]+.[0-999]+):([0-9999]+)/(.+))"
        let regex = try! NSRegularExpression(pattern: validRegex, options: [])
        
        if let result = regex.firstMatch(in: msg as String, options: [], range: NSMakeRange(0, msg.length)) {
            let deviceIp = msg.substring(with: result.range(at: 2))
            let devicePort = msg.substring(with: result.range(at: 3))
            let deviceLocationUrl = URL(string: msg.substring(with: result.range(at: 1)))
            
            let task = URLSession.shared.dataTask(with: deviceLocationUrl!) { (data, response, error) in
                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode == 200 {
                    let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                    let validRegex = "urn:upnp-org:serviceId:AVTransport.*<controlURL>(.*)</controlURL>"
                    let regex = try! NSRegularExpression(pattern: validRegex, options: [.dotMatchesLineSeparators, .caseInsensitive, .anchorsMatchLines])
                    
                    if let result = regex.firstMatch(in: dataString as String, options: [], range: NSMakeRange(0, dataString.length)) {
                        let devicecontrolUrlString = dataString.substring(with: result.range(at: 1))
                        let deviceControlUrl = URL(string: "http://\(deviceIp):\(devicePort)\(devicecontrolUrlString)")!
                        
                        let device = UPnPDevice(ip: deviceIp,
                                                port: devicePort,
                                                controlUrl: deviceControlUrl,
                                                trackDuration: "",
                                                relTime: "",
                                                currentTransportState: "")
                        self.delegate?.foundDevice(device: device)
                    }
                    return
                }
            }
            task.resume()
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        print("didConnectToAddress")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("didNotConnect");
        print("error:\(error?.localizedDescription ?? "error")")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        //print("didSendDataWithTag")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("didNotSendDataWithTag")
        print("error:\(error?.localizedDescription ?? "error")")
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("udpSocketDidClose")
        print("error:\(error?.localizedDescription ?? "error")")
    }
}
