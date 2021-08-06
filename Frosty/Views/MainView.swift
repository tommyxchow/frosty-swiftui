//
//  MainView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            StreamerListView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(Authentication())
    }
}
