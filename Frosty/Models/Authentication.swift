//
//  Authentication.swift
//  Frosty
//
//  Created by Tommy Chow on 6/9/21.
//

import Foundation

class Authentication: ObservableObject {
    private let secret = ""
    private var refreshToken: String?
    let clientID = "k6tnwmfv24ct9pzanhnp2x1yht30oi"
    var tokenIsValid: Bool = false
    @Published var userToken: String?
    @Published var isLoggedIn: Bool = false
    @Published var user: User?
    
    
    func getUserInfo() {
        let url = "https://api.twitch.tv/helix/users"
        let headers = ["Authorization" : "Bearer \(userToken!)", "Client-Id" : clientID]
        
        Request.perform(.GET, to: URL(string: url)!, headers: headers) { data in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            print(String(data: data, encoding: .utf8)!)
            
            if let response = try? decoder.decode(UserData.self, from: data) {
                DispatchQueue.main.async {
                    self.user = response.data[0]
                }
            } else {
                print("Failed to get user info")
            }
        }
    }
    
    func validate() {
        guard let userToken = userToken else {
            print("Missing user token!")
            return
        }
        
        var validateURL = URLComponents()
        validateURL.scheme = "https"
        validateURL.host = "id.twitch.tv"
        validateURL.path = "/oauth2/validate"
            
        let headers = ["Authorization" : userToken]
        
        Request.perform(.GET, to: validateURL.url!, headers: headers) { data in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            if let response = try? decoder.decode(ValidateResponse.self, from: data) {
                print(response)
                
            } else {
                print("Failed to decode validate response")
                self.tokenIsValid = false
            }
        }
    }
    
    func getDefaultToken() {
        var newLoginUrl = URLComponents()
        newLoginUrl.scheme = "https"
        newLoginUrl.host = "id.twitch.tv"
        newLoginUrl.path = "/oauth2/token"
                
        let clientQuery = URLQueryItem(name: "client_id", value: clientID)
        let redirectQuery = URLQueryItem(name: "client_secret", value: secret)
        let responseQuery = URLQueryItem(name: "grant_type", value: "client_credentials")
        
        newLoginUrl.queryItems = [clientQuery, redirectQuery, responseQuery]
        
        Request.perform(.POST, to: newLoginUrl.url!) { data in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            print(String(data: data, encoding: .utf8)!)
            
            if let result = try? decoder.decode(DefaultAccess.self, from: data) {
                DispatchQueue.main.async {
                    self.userToken = result.accessToken
                }
             } else {
                print("Failed to decode default token")
            }
        }
    }
    
}

private struct ValidateResponse: Decodable {
    let clientId: String
    let login: String
    let scopes: [String]
    let userId: String
    let expiresIn: Int
}

private struct DefaultAccess: Decodable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
}
