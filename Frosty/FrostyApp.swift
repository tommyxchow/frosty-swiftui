//
//  FrostyApp.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

@main
struct FrostyApp: App {
    @StateObject var auth: Authentication = Authentication()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                MainView()
                    .environmentObject(auth)
            }
        }
    }
}
