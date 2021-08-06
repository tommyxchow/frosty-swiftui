//
//  Authentication.swift
//  Frosty
//
//  Created by Tommy Chow on 6/9/21.
//

import Foundation
import AuthenticationServices
import KeychainAccess

class Authentication: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var isLoggedIn: Bool = false
    @Published var userToken: String?
    @Published var user: User?
    
    private let decoder = JSONDecoder()
    private let keychain = Keychain(server: "https://twitch.tv", protocolType: .https)
    private let secret = ""
    private var refreshToken: String?
    
    let clientID = "k6tnwmfv24ct9pzanhnp2x1yht30oi"
    var tokenIsValid: Bool = false
    
    override init() {
        super.init()
        
        if let token = keychain["userToken"] {
            userToken = token
            isLoggedIn = true
            Task {
                await getUserInfo()
            }
        } else if let token = keychain["defaultToken"] {
            userToken = token
        }
    }
    
    func clearTokens() {
        print("removing tokens")
        do {
            try keychain.remove("userToken")
        } catch {
            print("No user token in keychain")
        }
        
        do {
            try keychain.remove("defaultToken")
        } catch {
            print("No default token in keychain")
        }
    }
    
    func getUserInfo() async {
        let url = "https://api.twitch.tv/helix/users"
        let headers = ["Authorization" : "Bearer \(userToken!)", "Client-Id" : clientID]
        
        if let data = await Request.perform(.GET, to: URL(string: url)!, headers: headers) {
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
    
    func getDefaultToken() async {
        if let existingToken = keychain["defaultToken"] {
            print("Default token already exists")
            userToken = existingToken
            user = nil
            return
        }
        
        var newLoginUrl = URLComponents()
        newLoginUrl.scheme = "https"
        newLoginUrl.host = "id.twitch.tv"
        newLoginUrl.path = "/oauth2/token"
                
        let clientQuery = URLQueryItem(name: "client_id", value: clientID)
        let redirectQuery = URLQueryItem(name: "client_secret", value: secret)
        let responseQuery = URLQueryItem(name: "grant_type", value: "client_credentials")
        
        newLoginUrl.queryItems = [clientQuery, redirectQuery, responseQuery]
                
        if let data = await Request.perform(.POST, to: newLoginUrl.url!) {
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            print("Token")
            print(String(data: data, encoding: .utf8)!)
            
            if let result = try? decoder.decode(DefaultAccess.self, from: data) {
                keychain["defaultToken"] = result.accessToken
                userToken = result.accessToken
                user = nil
            } else {
                print("Failed to decode default token")
            }
        }
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
    
    func login() {
        if let token = keychain["userToken"] {
            userToken = token
            isLoggedIn = true
            Task {
                await getUserInfo()
            }
            return
        }
        
        var newLoginUrl = URLComponents()
        newLoginUrl.scheme = "https"
        newLoginUrl.host = "id.twitch.tv"
        newLoginUrl.path = "/oauth2/authorize"
        
        let clientQuery = URLQueryItem(name: "client_id", value: clientID)
        let redirectQuery = URLQueryItem(name: "redirect_uri", value: "auth://")
        let responseQuery = URLQueryItem(name: "response_type", value: "token")
        let scopesQuery = URLQueryItem(name: "scope", value: "chat:read chat:edit user:read:follows")
        
        newLoginUrl.queryItems = [clientQuery, redirectQuery, responseQuery, scopesQuery]
        
        let session = ASWebAuthenticationSession(url: newLoginUrl.url!, callbackURLScheme: "auth") { callbackURL, error in
            guard let callbackURL = callbackURL else {
                print("ERROR", error!, error!.localizedDescription)
                return
            }
            let fragment = "?" + callbackURL.fragment!
            let queryItems = URLComponents(string: fragment)?.queryItems
            let token = queryItems?.filter({ $0.name == "access_token" }).first?.value
            
            self.keychain["userToken"] = token!
            self.userToken = token!
            self.isLoggedIn = true
            Task {
                await self.getUserInfo()
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        if !session.start() {
            print("fail")
        }
    }
    
    func logout() {
        user = nil
        userToken = nil
        isLoggedIn = false
        
        do {
            try keychain.remove("userToken")
        } catch {
            print("No values in keychain")
        }
    }
    
    //    func validate() async {
    //        guard let userToken = userToken else {
    //            print("Missing user token!")
    //            return
    //        }
    //
    //        var validateURL = URLComponents()
    //        validateURL.scheme = "https"
    //        validateURL.host = "id.twitch.tv"
    //        validateURL.path = "/oauth2/validate"
    //
    //        let headers = ["Authorization" : userToken]
    //
    //        if let data = await Request.perform(.GET, to: validateURL.url!, headers: headers) {
    //            decoder.keyDecodingStrategy = .convertFromSnakeCase
    //
    //            if let response = try? decoder.decode(ValidateResponse.self, from: data) {
    //                print(response)
    //
    //            } else {
    //                print("Failed to decode validate response")
    //                self.tokenIsValid = false
    //            }
    //        }
    //    }
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
