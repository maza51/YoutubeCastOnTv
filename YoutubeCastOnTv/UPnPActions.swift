//
//  UPnPActions.swift
//  YoutubeCastOnTv
//
//  Created by kirill reutov on 29.03.2018.
//  Copyright © 2018 kirill reutov. All rights reserved.
//

import Foundation

class UPnPActions {
    public static func play(url: URL) {
        let action = "Play"
        let service = "AVTransport"
        let variables = "<InstanceID>0</InstanceID>\n<Speed>1</Speed>"
        let evenlope = getEvenlope(action: action, service: service, variables: variables)
        
        if sendAction(msg: evenlope, url: url, action: action, service: service).count > 1 {
        }
    }
    
    public static func pause(url: URL) {
        let action = "Pause"
        let service = "AVTransport"
        let variables = "<InstanceID>0</InstanceID>"
        let evenlope = getEvenlope(action: action, service: service, variables: variables)
        
        if sendAction(msg: evenlope, url: url, action: action, service: service).count > 1 {
        }
    }
    
    public static func stop(url: URL) {
        let action = "Stop"
        let service = "AVTransport"
        let variables = "<InstanceID>0</InstanceID>"
        let evenlope = getEvenlope(action: action, service: service, variables: variables)
        
        if sendAction(msg: evenlope, url: url, action: action, service: service).count > 1 {
        }
    }
    
    public static func seek(url: URL, time: String) {
        let action = "Seek"
        let service = "AVTransport"
        let variables = "<InstanceID>0</InstanceID><Unit>REL_TIME</Unit><Target>\(time)</Target>"
        let evenlope = getEvenlope(action: action, service: service, variables: variables)
        
        if sendAction(msg: evenlope, url: url, action: action, service: service).count > 1 {
        }
    }
    
    public static func setAvTransportUrl(url: URL, urlVideo: String) {
        let metaData = getUrlMetaData(url: urlVideo)
        let action = "SetAVTransportURI"
        let service = "AVTransport"
        let variables = "<InstanceID>0</InstanceID>\n<CurrentURI>\(urlVideo)</CurrentURI>\n<CurrentURIMetaData>\(metaData)</CurrentURIMetaData>"
        let evenlope = getEvenlope(action: action, service: service, variables: variables)
        
        if sendAction(msg: evenlope, url: url, action: action, service: service).count > 1 {
        }
    }
    
    public static func getVolume() {
        
    }
    
    public static func getTransportInfo(url: URL) -> String {
        let action = "GetTransportInfo"
        let service = "AVTransport"
        let variables = "<InstanceID>0</InstanceID>"
        let evenlope = getEvenlope(action: action, service: service, variables: variables)
        
        return sendAction(msg: evenlope, url: url, action: action, service: service)
    }
    
    public static func getPositionInfo(url: URL) -> String {
        let action = "GetPositionInfo"
        let service = "AVTransport"
        let variables = "<InstanceID>0</InstanceID>"
        let evenlope = getEvenlope(action: action, service: service, variables: variables)
        
        return sendAction(msg: evenlope, url: url, action: action, service: service)
    }
    
    private static func sendAction(msg: String, url: URL, action: String, service: String) -> String {
        let dispatchSemaphore = DispatchSemaphore(value: 0)
        var request: URLRequest
        request = URLRequest(url: url)
        request.setValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
        request.setValue("\"urn:schemas-upnp-org:service:\(service):1#\(action)\"", forHTTPHeaderField: "SOAPACTION")
        
        //request.timeoutInterval = 0.5
        request.httpMethod = "POST"
        request.httpBody = msg.data(using: .utf8)
        
        var tmp = ""
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Error in \(action): \(error!.localizedDescription)")
                dispatchSemaphore.signal()
                return
            }
            
            let httpResponse = response as! HTTPURLResponse
            if httpResponse.statusCode != 200 {
                let status = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                print("\(httpResponse.statusCode): \(status) in \(action)")
                print(String(data: data!, encoding: .utf8)!)
                dispatchSemaphore.signal()
                return
            }
            
            tmp = String(data: data!, encoding: .utf8)!
            dispatchSemaphore.signal()
        }
        task.resume()
        dispatchSemaphore.wait()
        return tmp
    }
    
    private static func getEvenlope(action: String, service: String, variables: String) -> String {
        return "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">\n" +
            "<s:Body>\n" +
            "<u:\(action) xmlns:u=\"urn:schemas-upnp-org:service:\(service):1\">\n" +
            "\(variables)\n" +
            "</u:\(action)>\n" +
            "</s:Body>\n" +
        "</s:Envelope>"
    }
    
    private static func getUrlMetaData(url: String) -> String {
        return "&lt;DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:sec=\"http://www.sec.co.kr/\"&gt; &lt;item id=\"f-0\" parentID=\"0\" restricted=\"0\"&gt; &lt;upnp:class&gt;object.item.videoItem&lt;/upnp:class&gt; &lt;res protocolInfo=\"http-get:*:video/mp4:DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000\" sec:URIType=\"public\"&gt;\(url)&lt;/res&gt; &lt;/item&gt;&lt;/DIDL-Lite&gt;"
    }
}
