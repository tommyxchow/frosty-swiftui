//
//  FrostyApp.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

@main
struct FrostyApp: App {
    @StateObject var authHandler: Authentication = Authentication()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(authHandler)
                .task {
                    await ChatManager.getGlobalEmotesBTTV()
                    await ChatManager.getGlobalEmotesFFZ()
                    await ChatManager.getGlobalEmotesTwitch(token: authHandler.userToken!)
                    
                    // print(await ChatManager.getBadges(badgeType: .global, token: authHandler.userToken!))
                }
        }
    }
}
