//
//  SettingsLoggedInView.swift
//  Frosty
//
//  Created by Tommy Chow on 6/9/21.
//

import SwiftUI

struct SettingsLoggedInView: View {
    let user: User
    var body: some View {
        Text("Logged in as \(user.displayName)")
    }
}

struct SettingsLoggedInView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsLoggedInView(user: User())
    }
}

