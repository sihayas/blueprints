//
//  VariableBlurView.swift
//  blueprints
//
//  Created by decoherence on 1/28/25.
//

import Foundation
import SwiftUI
import UIKit

extension UIBlurEffect {
  public static func variableBlurEffect(radius: Double, imageMask: UIImage) -> UIBlurEffect? {
    let methodType = (@convention(c) (AnyClass, Selector, Double, UIImage) -> UIBlurEffect).self
    let selectorName = ["imageMask:", "effectWithVariableBlurRadius:"].reversed().joined()
    let selector = NSSelectorFromString(selectorName)

    guard UIBlurEffect.responds(to: selector) else { return nil }

    let implementation = UIBlurEffect.method(for: selector)
    let method = unsafeBitCast(implementation, to: methodType)

    return method(UIBlurEffect.self, selector, radius, imageMask)
  }
}

struct VariableBlurView: UIViewRepresentable {
  let radius: Double
  let mask: Image

  func makeUIView(context: Context) -> UIVisualEffectView {
    let maskImage = ImageRenderer(content: mask).uiImage
    let effect = maskImage.flatMap {
      UIBlurEffect.variableBlurEffect(radius: radius, imageMask: $0)
    }
    return UIVisualEffectView(effect: effect)
  }

  func updateUIView(_ view: UIVisualEffectView, context: Context) {
    let maskImage = ImageRenderer(content: mask).uiImage
    view.effect = maskImage.flatMap {
      UIBlurEffect.variableBlurEffect(radius: radius, imageMask: $0)
    }
  }
}
