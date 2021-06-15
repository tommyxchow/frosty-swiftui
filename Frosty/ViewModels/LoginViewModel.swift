//
//  LoginViewModel.swift
//  Frosty
//
//  Created by Tommy Chow on 6/8/21.
//

import Foundation
import AuthenticationServices

@MainActor
class LoginViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
    
    func login(auth: Authentication) {
        var newLoginUrl = URLComponents()
        newLoginUrl.scheme = "https"
        newLoginUrl.host = "id.twitch.tv"
        newLoginUrl.path = "/oauth2/authorize"
        
        let clientQuery = URLQueryItem(name: "client_id", value: auth.clientID)
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
            
            auth.userToken = token!
            auth.isLoggedIn = true
            async {
                await auth.getUserInfo()
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        if !session.start() {
            print("fail")
        }
    }
}
