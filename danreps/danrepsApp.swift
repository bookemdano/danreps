//
//  danrepsApp.swift
//  danreps
//
//  Created by Daniel Francis on 2/1/25.
//

import SwiftUI

@main
struct danrepsApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationHandler.shared
    }
    var body: some Scene {
        WindowGroup {
            WelcomeView()
        }
    }
}
