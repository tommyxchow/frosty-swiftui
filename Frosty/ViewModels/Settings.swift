//
//  Settings.swift
//  Settings
//
//  Created by Tommy Chow on 8/11/21.
//

import Foundation
import SwiftUI

// TODO: Investigate @AppStorage to deal with storing settings in UserDefaults.

class Settings: ObservableObject {
    @Published var videoEnabled = true
}
