//
//  Test.swift
//  YoutubeCastOnTv
//
//  Created by kirill reutov on 01.04.2018.
//  Copyright © 2018 kirill reutov. All rights reserved.
//

import Foundation

class Test {
    // https://www.youtube.com/watch?v=rLj0AqudnmA
    static func go(id: String) -> String {
        
        let r = sendAction(url: URL(string: "http://www.youtube.com/get_video_info?video_id=\(id)")!)
        
        let rParts = r.components(separatedBy: "&")
        
        guard let streamMapPart = rParts.first(where: { (part) -> Bool in
            return part.contains("url_encoded_fmt_stream_map")
        })
            else {
                return ""
        }
        
        guard let s = streamMapPart.removingPercentEncoding else {
            return ""
        }
        
        let streamParts = s.replacingOccurrences(of: "url_encoded_fmt_stream_map=", with: "").components(separatedBy: ",")
        
        var u = [String : [String : String]]()
        for g in streamParts {
            let o = g.components(separatedBy: "&")
            var i = [String : String]()
            for p in o {
                var d = p.components(separatedBy: "=")
                if d.count > 1 {
                    i[d[0]] = d[1]
                }
            }
            if let f = i["quality"] {
                u[f] = i
            }
        }
        
        if let q = u["hd720"] {
            if let l = q["url"] {
                return l.removingPercentEncoding!
            }
        }
        
        return ""
        
        /*
        
        let videoDictionary = streamParts.reduce([AnyHashable : [AnyHashable : Any]](), { (previousVideos, streamPart) -> [AnyHashable : [AnyHashable : Any]] in
            
            // Map the streamparts components out like url parameters (&key=value&otherKey=otherValue) and convert to dictionary
            var dictionaryForQuality = streamPart.components(separatedBy: "&").reduce([AnyHashable : Any](), { (previous, videoPart) -> [AnyHashable : Any] in
                
                var next = previous
                let videoPartComponents = videoPart.components(separatedBy: "=")
                if videoPartComponents.count > 1 {
                    next[videoPartComponents[0]] = videoPartComponents[1]
                }
                
                return next
            })
            
            // Seems the & before sig is sometimes URL encoded. If we haven't pulled it out already,
            // let's decode then pull it out
            if dictionaryForQuality["sig"] == nil && dictionaryForQuality["signature"] == nil, let decodedStreamPart = streamPart.removingPercentEncoding {
                
                let decodedUrlParts = decodedStreamPart.components(separatedBy: "&")
                for part in decodedUrlParts {
                    let keyArray = part.components(separatedBy: "=")
                    guard keyArray.count > 1, keyArray[0] == "sig" || keyArray[0] == "signature" else {
                        continue
                    }
                    dictionaryForQuality["sig"] = keyArray[1]
                    break
                }
            }
            
            // If we have a quality then add it to the videos dictionary
            guard let quality = dictionaryForQuality["quality"] as? AnyHashable else {
                return previousVideos
            }
            
            var nextVideos = previousVideos
            nextVideos[quality] = dictionaryForQuality
            return nextVideos
        })
        //print(videoDictionary)
        print("===================")
        
        var streamQuality: String?
        if videoDictionary["medium"] != nil {
            streamQuality = "medium"
        } else if videoDictionary["small"] != nil {
            streamQuality = "small"
        }
        
        let quality = streamQuality
        print(quality)
        print("===================")
        
        
        guard let video = videoDictionary[quality!], let url = video["url"] as? String, let sig = (video["sig"] as? String ?? video["signature"] as? String), let videoString = "\(url)&signature=\(sig)".removingPercentEncoding, let videoURL = URL(string: videoString) else {
            return ""
        }
        
        
        print(videoURL)
        print("=================== videoURL")
        
        return videoURL.absoluteString
 
         */
        
    }
    
    private static func sendAction(url: URL) -> String {
        let dispatchSemaphore = DispatchSemaphore(value: 0)
        var request: URLRequest
        request = URLRequest(url: url)
        //request.setValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
        //request.setValue("\"urn:schemas-upnp-org:service:\(service):1#\(action)\"", forHTTPHeaderField: "SOAPACTION")
        
        request.httpMethod = "POST"
        //request.httpBody = msg.data(using: .utf8)
        
        
        
        var tmp = ""
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("Error : \(error!.localizedDescription)")
                dispatchSemaphore.signal()
                return
            }
            
            let httpResponse = response as! HTTPURLResponse
            if httpResponse.statusCode != 200 {
                let status = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                print("\(httpResponse.statusCode): \(status)")
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
}
