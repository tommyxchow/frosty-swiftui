//
//  MainView.swift
//  Frosty
//
//  Created by Tommy Chow on 5/30/21.
//

import SwiftUI

struct MainView: View {
    @State private var isPresented = false
    
    var body: some View {
        NavigationView {
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
                                print("Settings")
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainView()
                .environmentObject(Authentication())
        }
    }
}
