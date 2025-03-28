//
//  UIState.swift
//  blueprints
//
//  Created by decoherence on 3/28/25.
//

import SwiftUI

struct SymmetryState {
    var leading: Properties
    var center: Properties
    var trailing: Properties
    
    struct Properties {
        var showContent: Bool
        var offset: CGPoint
        var size: CGSize
        var cornerRadius: CGFloat = 22
    }
}

/// Manages the UI states and properties of the app across windows.
class UIState: ObservableObject {
    static let shared = UIState()

    // MARK: - Symmetry Window Presenter-related state
    private var floatingBarWindow: UIWindow?

    enum SymmetryMode: String {
        case collapsed
        case feed
        case reply
    }

    @Published var size: CGSize = .zero
    @Published var symmetryState: SymmetryMode = .collapsed
    // MARK: - Dark Mode

    func enableDarkMode() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .forEach { windowScene in
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = .dark
                }
            }
    }
}
