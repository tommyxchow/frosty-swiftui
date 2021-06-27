//
//  Request.swift
//  Frosty
//
//  Created by Tommy Chow on 6/3/21.
//

import Foundation

struct Request {
    static private let session = URLSession.shared
    
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
    }
    
    static func perform(_ method: HTTPMethod, to url: URL, headers: [String:String]? = nil) async -> Data? {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
                        
        if let headers = headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
                
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("ERROR: NON 200-LEVEL RESPONSE")
                return nil
            }
            
            return data
        } catch {
            print("Request failed to \(url)")
            return nil
        }
    }
}
