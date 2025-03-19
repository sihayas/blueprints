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
            HoloPreview()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .ignoresSafeArea()
                .environmentObject(WindowState.shared)
        }
    }
}
