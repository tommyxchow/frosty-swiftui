//
//  MainView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var auth: Authentication
    @State var isPresented = false
    
    var body: some View {
        StreamerListView()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = true
                    }, label: {
                        Label("Settings", systemImage: "gearshape")
                    })
                }
            }
            .sheet(isPresented: $isPresented, content: {
                NavigationView {
                    SettingsView()
                        .onAppear {
                            print("SEttINGS")
                        }
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    isPresented = false
                                }, label: {
                                    Text("Dismiss")
                                })
                            }
                        }
                }
            })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainView()
        }
    }
}
