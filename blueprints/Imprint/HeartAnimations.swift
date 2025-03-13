//
//  HeartAnimations.swift
//  vellum
//
//  Created by decoherence on 1/28/25.
//

import SwiftUI

struct AnimationValues {
    var scale = 1.0
    var verticalStretch = 1.0
    var horizontalStretch = 1.0
    var verticalTranslation = 0.0
    var horizontalTranslation = 0.0
    var angle = Angle.zero
    var horizontalSpin = Angle.zero
}

struct HeartbeatAnimatorModifier: ViewModifier {
    var triggerKeyframe: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: AnimationValues(), trigger: triggerKeyframe) { content, value in
            content
                .foregroundStyle(.white)
                .rotation3DEffect(value.horizontalSpin, axis: (x: 0, y: 1, z: 0))
                .rotationEffect(value.angle)
                .scaleEffect(value.scale)
                .scaleEffect(y: value.verticalStretch)
                .scaleEffect(x: value.horizontalStretch)
                .offset(y: value.verticalTranslation)
                .offset(x: value.horizontalTranslation)
        } keyframes: { _ in
            KeyframeTrack(\.horizontalSpin) {
                CubicKeyframe(.degrees(0), duration: 0.1)
                CubicKeyframe(.degrees(360), duration: 0.5)
            }
            KeyframeTrack(\.verticalStretch) {
                CubicKeyframe(1.0, duration: 0.1)
                CubicKeyframe(0.3, duration: 0.15)
                CubicKeyframe(1.5, duration: 0.1)
                CubicKeyframe(1.05, duration: 0.15)
                CubicKeyframe(1.0, duration: 0.88)
                CubicKeyframe(0.8, duration: 0.1)
                CubicKeyframe(1.04, duration: 0.4)
                CubicKeyframe(1.0, duration: 0.22)
            }
            KeyframeTrack(\.horizontalStretch) {
                CubicKeyframe(1.0, duration: 0.1)
                CubicKeyframe(1.3, duration: 0.15)
                CubicKeyframe(0.5, duration: 0.1)
                CubicKeyframe(1.05, duration: 0.15)
                CubicKeyframe(1.0, duration: 0.88)
                CubicKeyframe(1.2, duration: 0.1)
                CubicKeyframe(0.98, duration: 0.4)
                CubicKeyframe(1.0, duration: 0.22)
            }
            KeyframeTrack(\.scale) {
                LinearKeyframe(1.0, duration: 0.5)
                SpringKeyframe(3.6, duration: 0.15, spring: .bouncy)
                SpringKeyframe(0.6, duration: 0.15, spring: .bouncy)
                SpringKeyframe(7.0, duration: 0.18, spring: .bouncy)
                SpringKeyframe(0.9, duration: 0.15, spring: .bouncy)
                SpringKeyframe(1.2, duration: 0.15, spring: .bouncy)
                LinearKeyframe(1.0, duration: 0.2)
            }
            KeyframeTrack(\.verticalTranslation) {
                LinearKeyframe(0.0, duration: 0.1)
                SpringKeyframe(15.0, duration: 0.15, spring: .bouncy)
                SpringKeyframe(-90.0, duration: 1.0, spring: .bouncy)
                SpringKeyframe(0.0, spring: .bouncy)
            }
        }
    }
}

struct HeartbreakLeftAnimatorModifier: ViewModifier {
    var triggerKeyframe: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: AnimationValues(), trigger: triggerKeyframe) { content, value in
            content
                .foregroundStyle(.white)
                .rotation3DEffect(value.horizontalSpin, axis: (x: 0, y: 1, z: 0))
                .rotationEffect(value.angle)
                .scaleEffect(value.scale)
                .scaleEffect(y: value.verticalStretch)
                .scaleEffect(x: value.horizontalStretch)
                .offset(y: value.verticalTranslation)
                .offset(x: value.horizontalTranslation)
        } keyframes: { _ in
            KeyframeTrack(\.horizontalSpin) {
                CubicKeyframe(.degrees(0), duration: 0.1)
                CubicKeyframe(.degrees(-360), duration: 0.5)
            }
            KeyframeTrack(\.angle) {
                CubicKeyframe(.zero, duration: 0.58)
                CubicKeyframe(.degrees(16), duration: 0.125)
                CubicKeyframe(.degrees(-16), duration: 0.125)
                CubicKeyframe(.degrees(16), duration: 0.125)
                CubicKeyframe(.zero, duration: 0.125)
            }
            KeyframeTrack(\.verticalStretch) {
                CubicKeyframe(1.0, duration: 0.1)
                CubicKeyframe(0.3, duration: 0.15)
                CubicKeyframe(1.5, duration: 0.1)
                CubicKeyframe(1.0, duration: 0.15)
                CubicKeyframe(1.0, duration: 0.88)
                CubicKeyframe(1.0, duration: 0.1)
                CubicKeyframe(1.04, duration: 0.4)
                CubicKeyframe(1.0, duration: 0.22)
            }
            KeyframeTrack(\.horizontalStretch) {
                CubicKeyframe(1.0, duration: 0.1)
                CubicKeyframe(1.3, duration: 0.15)
                CubicKeyframe(0.5, duration: 0.1)
                CubicKeyframe(1.25, duration: 0.15)
                CubicKeyframe(1.0, duration: 0.88)
                CubicKeyframe(1.0, duration: 0.1)
                CubicKeyframe(0.98, duration: 0.4)
                CubicKeyframe(1.0, duration: 0.22)
            }
            KeyframeTrack(\.verticalTranslation) {
                LinearKeyframe(0.0, duration: 0.1)
                SpringKeyframe(15.0, duration: 0.15, spring: .bouncy)
                SpringKeyframe(-90.0, duration: 1.0, spring: .bouncy)
                SpringKeyframe(0.0, spring: .bouncy)
            }

            KeyframeTrack(\.horizontalTranslation) {
                LinearKeyframe(0.0, duration: 0.8)
                SpringKeyframe(-8.0, duration: 1.0, spring: .bouncy)
                SpringKeyframe(-2.0, spring: .bouncy)
            }
            KeyframeTrack(\.scale) {
                LinearKeyframe(1.0, duration: 0.5)
                LinearKeyframe(3.5, duration: 0.15)


                SpringKeyframe(3.5, duration: 0.15, spring: .bouncy)

                LinearKeyframe(3.5, duration: 1.0)
                LinearKeyframe(1.0, duration: 0.2)
            }
        }
    }
}

struct HeartbreakRightAnimatorModifier: ViewModifier {
    var triggerKeyframe: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: AnimationValues(), trigger: triggerKeyframe) { content, value in
            content
                .foregroundStyle(.white)
                .rotation3DEffect(value.horizontalSpin, axis: (x: 0, y: 1, z: 0))
                .rotationEffect(value.angle)
                .scaleEffect(value.scale)
                .scaleEffect(y: value.verticalStretch)
                .scaleEffect(x: value.horizontalStretch)
                .offset(y: value.verticalTranslation)
                .offset(x: value.horizontalTranslation)
        } keyframes: { _ in
            KeyframeTrack(\.horizontalSpin) {
                CubicKeyframe(.degrees(0), duration: 0.1)
                CubicKeyframe(.degrees(-360), duration: 0.5)
            }
            KeyframeTrack(\.angle) {
                CubicKeyframe(.zero, duration: 0.58)
                CubicKeyframe(.degrees(16), duration: 0.125)
                CubicKeyframe(.degrees(-16), duration: 0.125)
                CubicKeyframe(.degrees(16), duration: 0.125)
                CubicKeyframe(.zero, duration: 0.125)
            } 
            KeyframeTrack(\.verticalStretch) {
                CubicKeyframe(1.0, duration: 0.1)
                CubicKeyframe(0.3, duration: 0.15)
                CubicKeyframe(1.5, duration: 0.1)
                CubicKeyframe(1.0, duration: 0.15)
                CubicKeyframe(1.0, duration: 0.88)
                CubicKeyframe(1.0, duration: 0.1)
                CubicKeyframe(1.04, duration: 0.4)
                CubicKeyframe(1.0, duration: 0.22)
            }
            KeyframeTrack(\.horizontalStretch) {
                CubicKeyframe(1.0, duration: 0.1)
                CubicKeyframe(1.3, duration: 0.15)
                CubicKeyframe(0.5, duration: 0.1)
                CubicKeyframe(1.25, duration: 0.15)
                CubicKeyframe(1.0, duration: 0.88)
                CubicKeyframe(1.0, duration: 0.1)
                CubicKeyframe(0.98, duration: 0.4)
                CubicKeyframe(1.0, duration: 0.22)
            }
            KeyframeTrack(\.verticalTranslation) {
                LinearKeyframe(0.0, duration: 0.1)
                SpringKeyframe(15.0, duration: 0.15, spring: .bouncy)
                SpringKeyframe(-90.0, duration: 1.0, spring: .bouncy)
                SpringKeyframe(0.0, spring: .bouncy)
            }
            KeyframeTrack(\.horizontalTranslation) {
                LinearKeyframe(0.0, duration: 0.8)
                SpringKeyframe(8.0, duration: 1.0, spring: .bouncy)
                SpringKeyframe(2.0, spring: .bouncy)
            }
            KeyframeTrack(\.scale) {
                LinearKeyframe(1.0, duration: 0.5)
                LinearKeyframe(3.5, duration: 0.15)

                SpringKeyframe(3.5, duration: 0.15, spring: .bouncy)

                LinearKeyframe(3.5, duration: 1.0)

                LinearKeyframe(1.0, duration: 0.2)
            }
        }
    }
}

extension View {
    func applyHeartbeatAnimator(triggerKeyframe: Int) -> some View {
        modifier(HeartbeatAnimatorModifier(triggerKeyframe: triggerKeyframe))
    }

    func applyHeartbreakLeftAnimator(triggerKeyframe: Int) -> some View {
        modifier(HeartbreakLeftAnimatorModifier(triggerKeyframe: triggerKeyframe))
    }

    func applyHeartbreakRightAnimator(triggerKeyframe: Int) -> some View {
        modifier(HeartbreakRightAnimatorModifier(triggerKeyframe: triggerKeyframe))
    }
}
