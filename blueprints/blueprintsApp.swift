//
//  blueprintsApp.swift
//  blueprints
//
//  Created by decoherence on 1/28/25.
//

import SwiftUI

@main
struct blueprintsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ViewControllerPreview()
                .ignoresSafeArea()
                .environmentObject(WindowState.shared)
        }
    }
}
