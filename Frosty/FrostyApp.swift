//
//  FrostyApp.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

@main
struct FrostyApp: App {
    @StateObject var auth = Authentication()
    @StateObject var settings = Settings()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(auth)
                .environmentObject(settings)
        }
    }
}
