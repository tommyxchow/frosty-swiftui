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
                    await EmoteManager.getGlobalEmotesBTTV()
                    await EmoteManager.getGlobalEmotesFFZ()
                    await EmoteManager.getGlobalEmotesTwitch(token: authHandler.userToken!)
                }
        }
    }
}
