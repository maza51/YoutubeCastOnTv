//
//  YoutubeParse.swift
//  YoutubeCastOnTv
//
//  Created by kirill reutov on 02.04.2018.
//  Copyright © 2018 kirill reutov. All rights reserved.
//

import Foundation

class YoutubeParse {
    
    static func go(id: String) -> String {
        
        let r = sendAction(url: URL(string: "http://www.youtube.com/get_video_info?video_id=\(id)&el=detailpage&ps=default&eurl=&gl=US&hl=en")!)
        
        let parts = r.components(separatedBy: "&")
        
        guard let vp = parts.first(where: { (part) -> Bool in
            return part.contains("url_encoded_fmt_stream_map")
        })
            else {
                return ""
        }
        
        guard var s = vp.removingPercentEncoding else {
            return ""
        }
        
        s = s.replacingOccurrences(of: "url_encoded_fmt_stream_map=", with: "")
        
        let k = s.components(separatedBy: ",")
        
        var u = [String : [String : String]]()
        for g in k {
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
                
                //print("\n\n\(i["type"])\n\n")
            }
        }
        
        if let q = u["hd720"] {
            if let l = q["url"] {
                return l.removingPercentEncoding!
            }
        } else {
            return "No video\n720p quality"
        }
        
        return ""
    }
    
    private static func sendAction(url: URL) -> String {
        let dispatchSemaphore = DispatchSemaphore(value: 0)
        var request: URLRequest
        request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
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
