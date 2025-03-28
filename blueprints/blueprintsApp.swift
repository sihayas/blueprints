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
    let uiState = UIState.shared

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                VStack {
                    Image("ramp")
                        .resizable()
                        .scaledToFit()
                        .clipShape(Capsule())
                }
                .frame(maxHeight: 32)

                SymmetryView()
                    .environmentObject(uiState)
                    .onAppear {
                        uiState.enableDarkMode()
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(WindowState.shared)
        }
    }
}
