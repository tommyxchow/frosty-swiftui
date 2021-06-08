//
//  Authentication.swift
//  Frosty
//
//  Created by Tommy Chow on 6/1/21.
//

import Foundation
import AuthenticationServices

class Authentication: NSObject, ObservableObject {
    private let secret = ""
    private var refreshToken: String? = nil
    private(set) static var userToken: String? = ""
    private var tokenIsValid: Bool = false
    @Published var isLoggedIn: Bool = false
    let clientID = "k6tnwmfv24ct9pzanhnp2x1yht30oi"
    
    
    var loginUrl: URL {
        var newLoginUrl = URLComponents()
        newLoginUrl.scheme = "https"
        newLoginUrl.host = "id.twitch.tv"
        newLoginUrl.path = "/oauth2/authorize"
        
        // Example URL "https://id.twitch.tv/oauth2/authorize?client_id=k6tnwmfv24ct9pzanhnp2x1yht30oi&redirect_uri=auth://&response_type=token&scope=chat:read%20chat:edit%20user:read:follows"
        
        let clientQuery = URLQueryItem(name: "client_id", value: clientID)
        let redirectQuery = URLQueryItem(name: "redirect_uri", value: "auth://")
        let responseQuery = URLQueryItem(name: "response_type", value: "token")
        let scopesQuery = URLQueryItem(name: "scope", value: "chat:read chat:edit user:read:follows")
        
        newLoginUrl.queryItems = [clientQuery, redirectQuery, responseQuery, scopesQuery]
        
        return newLoginUrl.url!
    }
        
    func login() {
        let session = ASWebAuthenticationSession(url: loginUrl, callbackURLScheme: "auth") { callbackURL, error in
            guard let callbackURL = callbackURL else {
                print("ERROR", error!, error!.localizedDescription)
                return
            }
            let fragment = "?" + callbackURL.fragment!
            let queryItems = URLComponents(string: fragment)?.queryItems
            let token = queryItems?.filter({ $0.name == "access_token" }).first?.value
            
            Self.userToken = token!
            self.tokenIsValid = true
            self.isLoggedIn = true
                        
            self.getUserInfo()
        }
        session.presentationContextProvider = self
        // session.prefersEphemeralWebBrowserSession = true
        if !session.start() {
            print("fail")
        }
    }
    
    func getUserInfo() {
        let url = "https://api.twitch.tv/helix/users"
        let headers = ["Authorization" : "Bearer \(Self.userToken!)", "Client-Id" : clientID]
        
        Request.perform(.GET, to: URL(string: url)!, headers: headers) { data in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            print(String(data: data, encoding: .utf8)!)
            
            if let response = try? decoder.decode(UserData.self, from: data) {
                print(response)
            } else {
                print("Failed to get user info")
            }
        }
    }
    
    
    func validate() {
//        guard let userToken = userToken else {
//            print("Missing user token!")
//            return
//        }
        
        var validateURL = URLComponents()
        validateURL.scheme = "https"
        validateURL.host = "id.twitch.tv"
        validateURL.path = "/oauth2/validate"
            
        let headers = ["Authorization" : Self.userToken!]
        
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
                print(result)
            } else {
                print("Failed to decode deafult token")
            }
        }
        
    }
}

extension Authentication: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

struct ValidateResponse: Decodable {
    let clientId: String
    let login: String
    let scopes: [String]
    let userId: String
    let expiresIn: Int
}

struct DefaultAccess: Decodable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
}
