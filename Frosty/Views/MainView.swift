//
//  MainView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var auth = Authentication()
    var body: some View {
        NavigationView {
            StreamerListView()
                .environmentObject(auth)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
