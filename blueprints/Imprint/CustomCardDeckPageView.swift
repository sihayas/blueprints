//
//  CustomCardDeckPageView.swift
//  acusia
//
//  Created by decoherence on 8/15/24.
//
/// This is a fork of the CardDeckPageView in the BigUIPaging package.
/// The original code had a default scaleEffect applied to it. This
/// remedies that.
///
/// Changes:
/// - Removed the scaleEffect modifier from the CustomCardDeckPageView
/// - Changed the swingOutMultiplier and subsequent xOffset padding multiplier.
/// - Changed default corner radius.
/// - Added a 3D rotation tilt.
/// - Removed the ".CardStyle" property which added a Mask/RoundedRectangle to each card.

import BigUIPaging
import SwiftUI

#Preview {
    CardDeckPreview()
        .frame(width: 240, height: 320)
}

struct CardDeckPreview: View {
    @Namespace private var namespace
    @State private var selection: Int = 1
    
    var body: some View {
        PageView(selection: $selection) {
            ForEach([1, 2], id: \.self) { index in
                if index == 1 {
                    Rectangle()
                        .fill(.red)
                } else {
                    Rectangle()
                        .fill(.blue)
                }
            }
        }
        .pageViewStyle(.customCardDeck)
        .pageViewCardShadow(.visible)
    }
    
    var indicatorSelection: Binding<Int> {
        .init {
            selection - 1
        } set: { newValue in
            selection = newValue + 1
        }
    }
}

@available(macOS, unavailable)
@available(iOS 16.0, *)
public struct CustomCardDeckPageViewStyle: PageViewStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        CustomCardDeckPageView(configuration)
    }
}

struct CustomCardDeckPageView: View {
    typealias Value = PageViewStyleConfiguration.Value
    typealias Configuration = PageViewStyleConfiguration
    
    struct Page: Identifiable {
        let index: Int
        let value: Value
        
        var id: Value {
            return value
        }
    }
    
    let configuration: Configuration
    
    @State private var dragProgress = 0.0
    @State private var selectedIndex = 0
    @State private var pages = [Page]()
    @State private var containerSize = CGSize.zero
    
    @Environment(\.cardCornerRadius) private var cornerRadius
    @Environment(\.cardShadowDisabled) private var shadowDisabled

    init(_ configuration: Configuration) {
        self.configuration = configuration
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ForEach(pages) { page in
                configuration.content(page.value)
                    .zIndex(zIndex(for: page.index))
                    .offset(x: xOffset(for: page.index))
                    .scaleEffect(scale(for: page.index))
                    .rotationEffect(.degrees(rotation(for: page.index)))
                    // .rotation3DEffect(
                    //     tiltAngle(for: page.index),
                    //     axis: (x: 0, y: 1, z: 0),
                    //     perspective: 0.5
                    // )
                    .shadow(color: shadow(for: page.index), radius: 30, y: 20)
            }
        }
        .measure($containerSize)
        .highPriorityGesture(dragGesture)
        .task {
            makePages(from: configuration.selection.wrappedValue)
        }
        .onChange(of: selectedIndex) { _, newValue in
            configuration.selection.wrappedValue = pages[newValue].value
        }
        .onChange(of: configuration.selection.wrappedValue) { _, newValue in
            makePages(from: newValue)
            self.dragProgress = 0.0
        }
    }
    
    func makePages(from value: Value) {
        let (values, index) = configuration.values(surrounding: value)
        pages = values.enumerated().map {
            Page(index: $0.offset, value: $0.element)
        }
        selectedIndex = index
    }
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                self.dragProgress = -(value.translation.width / containerSize.width)
            }
            .onEnded { _ in
                snapToNearestIndex()
            }
    }
    
    func snapToNearestIndex() {
        let threshold = 0.3
        if abs(dragProgress) < threshold {
            withAnimation(.bouncy) {
                self.dragProgress = 0.0
            }
        } else {
            let direction = dragProgress < 0 ? -1 : 1
            withAnimation(.smooth(duration: 0.25)) {
                go(to: selectedIndex + direction)
                self.dragProgress = 0.0
            }
        }
    }
    
    func go(to index: Int) {
        let maxIndex = pages.count - 1
        if index > maxIndex {
            selectedIndex = maxIndex
        } else if index < 0 {
            selectedIndex = 0
        } else {
            selectedIndex = index
        }
        dragProgress = 0
    }
    
    func currentPosition(for index: Int) -> Double {
        progressIndex - Double(index)
    }
    
    // MARK: - Geometry
    
    var progressIndex: Double {
        dragProgress + Double(selectedIndex)
    }
    
    func zIndex(for index: Int) -> Double {
        let position = currentPosition(for: index)
        return -abs(position)
    }
    
    // Originally, the padding was set to 10. But to show more of the cards "behind",
    // decrease the value. Subsequently, you have to change the swingOutMultiplier to multiply by double the new value.
    func xOffset(for index: Int) -> Double {
        let cardPaddingFactor = 10.0 // Adjust the value to show more cards "behind"
        let padding = containerSize.width / cardPaddingFactor
        let x = (Double(index) - progressIndex) * padding
        let maxIndex = pages.count - 1
        if index == selectedIndex && progressIndex < Double(maxIndex) && progressIndex > 0 {
            return x * swingOutMultiplier
        }
        return x
    }
    
    var swingOutMultiplier: Double {
        return abs(sin(Double.pi * progressIndex) * 20) // Double the padding factor ^
    }
    
    func scale(for index: Int) -> CGFloat {
        return 1.0 - (0.1 * abs(currentPosition(for: index)))
    }
    
    func rotation(for index: Int) -> Double {
        return -currentPosition(for: index) * 8
    }
    
    func tiltAngle(for index: Int) -> Angle {
        let maxTilt: Double = -30 // 45 is best with the default padding/swing out multiplier.
        return .degrees(dragProgress * maxTilt)
    }
    
    func shadow(for index: Int) -> Color {
        guard shadowDisabled == false else {
            return .clear
        }
        let index = Double(index)
        let progress = 1.0 - abs(progressIndex - index)
        let opacity = 0.3 * progress
        return .black.opacity(opacity)
    }
}

// MARK: - Styling options

extension EnvironmentValues {
    struct CardCornerRadius: EnvironmentKey {
        static var defaultValue: Double? = nil
    }
    
    var cardCornerRadius: Double? {
        get { self[CardCornerRadius.self] }
        set { self[CardCornerRadius.self] = newValue }
    }
    
    struct CardShadowDisabled: EnvironmentKey {
        static var defaultValue: Bool = false
    }
    
    var cardShadowDisabled: Bool {
        get { self[CardShadowDisabled.self] }
        set { self[CardShadowDisabled.self] = newValue }
    }
}

@available(macOS, unavailable)
public extension PageViewStyle where Self == CustomCardDeckPageViewStyle {
    static var customCardDeck: CustomCardDeckPageViewStyle {
        CustomCardDeckPageViewStyle()
    }
}

extension View {
    /// Measures the geometry of the attached view.
    func measure(_ size: Binding<CGSize>) -> some View {
        background {
            GeometryReader { reader in
                Color.clear.preference(
                    key: ViewSizePreferenceKey.self,
                    value: reader.size
                )
            }
        }
        .onPreferenceChange(ViewSizePreferenceKey.self) {
            size.wrappedValue = $0 ?? .zero
        }
    }
}

struct ViewSizePreferenceKey: PreferenceKey {
    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        value = nextValue() ?? value
    }
    
    static var defaultValue: CGSize? = nil
}
