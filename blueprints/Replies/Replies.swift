//
//  Replies.swift
//  blueprints
//
//  Created by decoherence on 1/12/25.
//
/// A SwiftUI interface for displaying threaded replies in a layered,
/// vertically stacked sheet style. Each reply can collapse into a
/// compact layer and push new layers on top, enabling navigation
/// through conversations without leaving the context of the thread.
///
import SwiftUI
import Transmission


struct RepliesSheet_Previews: PreviewProvider {
    static var previews: some View {
        RepliesSheet(size: UIScreen.main.bounds.size, minHomeHeight: 32)
            .environmentObject(WindowState.shared)
    }
}

class WindowState: ObservableObject {
    static let shared = WindowState()

    @Published var showSearchSheet: Bool = false

    // Reply
    @Published var isSplit: Bool = false // Split the screen
    @Published var isSplitFull: Bool = false // Prevent gesture with the scrollview
    @Published var isOffsetAtTop: Bool = true // Prevent gesture with the split
    @Published var isLayered: Bool = false // Layered replies

    private init() {}
}

class LayerManager: ObservableObject {
    @Published var layers: [Layer] = [Layer(maskHeight: 0)]
    @Published var viewSize: CGSize = .zero

    struct Layer: Identifiable {
        let id = UUID()
        var selectedReply: Reply? // Match geometry
        
        var isHidden: Bool = false // Controls reply collapse & hiding hosting content.
        var isCollapsed: Bool = false // Indicates if the layer is collapsed.

        var baseHeight: CGFloat = 0 // Store the calculated height
        var maskHeight: CGFloat // Mask height for the layer
    }

    func pushLayer() {
        layers.append(Layer(maskHeight: viewSize.height))
    }
    
    func popLayer(at index: Int) {
        guard layers.indices.contains(index) else { return }
        layers.remove(at: index)
    }

    func previousLayer(before index: Int) -> Layer? {
        let previousIndex = index - 1
        guard layers.indices.contains(previousIndex) else { return nil }
        return layers[previousIndex]
    }
}

struct RepliesSheet: View {
    @EnvironmentObject private var windowState: WindowState
    @StateObject private var layerManager = LayerManager()

    var size: CGSize
    var minHomeHeight: CGFloat

    var body: some View {
        let collapsedHeight = 35.0 * 3
        let collapsedOffset = 35.0 * 2

        ZStack(alignment: .top) {
            ForEach(Array(layerManager.layers.enumerated()), id: \.element.id) { index, layer in
                LayerView(
                    layerManager: layerManager,
                    width: size.width,
                    height: size.height,
                    collapsedHeight: collapsedHeight,
                    collapsedOffset: collapsedOffset,
                    layer: layer,
                    index: index
                )
                .zIndex(Double(layerManager.layers.count - index))
            }

            if layerManager.layers.count > 1 {
                Rectangle()
                    .background(
                        VariableBlurView(radius: 4, mask: Image(.gradient))
                            .scaleEffect(y: -1)
                    )
                    .foregroundColor(.clear)
                    .frame(width: size.width, height: collapsedOffset * CGFloat(layerManager.layers.count))
                    .animation(.spring(), value: layerManager.layers.count)
                    .zIndex(1.5)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .top) // Important to align collapsed layers.
        .onReceive(layerManager.$layers) { layers in
            windowState.isLayered = layers.count > 1
        }
        .onAppear {
            layerManager.viewSize = size
            layerManager.layers[0].maskHeight = size.height // Set initial mask height
        }
    }
}

// MARK: LayerView

struct LayerView: View {
    @EnvironmentObject private var windowState: WindowState
    @ObservedObject var layerManager: LayerManager

    @State private var scrollState: (phase: ScrollPhase, context: ScrollPhaseChangeContext)?
    @State private var scrollDisabled = false
    @State private var isOffsetAtTop = true
    @State private var blurRadius: CGFloat = 0
    @State private var scale: CGFloat = 1
    @Namespace private var namespace

    let colors: [Color] = [.red, .green, .blue, .orange, .purple, .pink, .yellow]
    let width: CGFloat
    let height: CGFloat
    let collapsedHeight: CGFloat
    let collapsedOffset: CGFloat
    let layer: LayerManager.Layer
    let index: Int
    let cornerRadius: CGFloat = 20

    var body: some View {
        ZStack {
            LayerScrollViewWrapper(
                scrollState: $scrollState,
                scrollDisabled: $scrollDisabled,
                isOffsetAtTop: $isOffsetAtTop,
                blurRadius: $blurRadius,
                scale: $scale,
                width: width,
                height: height,
                index: index,
                collapsedHeight: collapsedHeight,
                collapsedOffset: collapsedOffset,
                layerManager: layerManager,
                layer: layer,
                namespace: namespace
            )
        }
        .edgesIgnoringSafeArea(.all)
        .frame(minWidth: width, minHeight: height)
        .frame(height: layer.maskHeight, alignment: .top)
        .overlay(alignment: .bottom) {
            VStack(alignment: .leading) { // Make sure it's always top leading aligned.
                VStack(alignment: .leading) { // Reserve space for match geometry to work.
                    if layer.selectedReply != nil {
                        ReplyView(reply: layer.selectedReply!, isCollapsed: layer.isHidden)
                            .matchedGeometryEffect(id: layer.selectedReply!.id, in: namespace)
                            .transition(.scale(1.0))
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                            .animation(.spring().delay(2), value: layer.selectedReply)
                    }
                }
                .frame(width: width, height: collapsedHeight, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
        }
        // .background(layer.isCollapsed ? colors[index % colors.count] : .clear)
        .background(.black.opacity(layer.isHidden ? 0 : 1.0))
        .animation(.spring(), value: layer.isHidden)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius, topTrailingRadius: 0))
        .contentShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius, topTrailingRadius: 0)) // Prevent touch inputs beyond.
        .overlay(
            BottomLeftRightArcPath(cornerRadius: cornerRadius)
                .strokeBorder(
                    Color(UIColor.systemGray6),
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .padding(.horizontal, 12)
        )
        .simultaneousGesture( // MARK: Layer Drag Gestures
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    let verticalDrag = value.translation.height

                    guard verticalDrag > 0 else { return }

                    let currentLayer = layer

                    // Pop the current layer, push the previous.
                    if isOffsetAtTop, !currentLayer.isCollapsed {
                        // Can't push a previous layer if it's the first layer.
                        guard index > 0 else { return }
                        print("Popping previous layer")

                        if !scrollDisabled { scrollDisabled = true }

                        let previousIndex = index - 1
                        let previousLayer = layerManager.layers[previousIndex]

                        let previousHeight = previousLayer.maskHeight
                        let newHeight = previousHeight + verticalDrag / 20

                        if previousLayer.isCollapsed {
                            // Push previous layer.
                            layerManager.layers[previousIndex].maskHeight = newHeight

                            // Pop the current, animated through .animation.
                            blurRadius = min(max(verticalDrag / 100, 0), 4)
                            scale = 1 - verticalDrag / 1000
                        }
                    }

                    // Push the current layer.
                    if currentLayer.isCollapsed {
                        let currentHeight = currentLayer.maskHeight
                        let newHeight = currentHeight + verticalDrag / 20

                        layerManager.layers[index].maskHeight = newHeight

                        if verticalDrag > 80 {
                            layerManager.layers[index].isHidden = false
                        }
                    }
                }
                .onEnded { value in
                    let verticalDrag = value.translation.height
                    let verticalVelocity = value.velocity.height
                    let velocityThreshold: CGFloat = 500
                    let shouldExpand = verticalDrag > height / 2 || verticalVelocity > velocityThreshold

                    scrollDisabled = false

                    guard verticalDrag > 0 else { return }

                    let currentLayer = layer

                    // Pop the current layer, push the previous.
                    if isOffsetAtTop, !currentLayer.isCollapsed {
                        guard index > 0 else { return }

                        let previousIndex = index - 1
                        let previousLayer = layerManager.layers[previousIndex]

                        if previousLayer.isCollapsed {
                            if shouldExpand {
                                // Expand the previous layer & scale away the current.
                                layerManager.layers[previousIndex].isHidden = false

                                withAnimation(.spring()) {
                                    layerManager.popLayer(at: index) // Pop the current layer.
                                    layerManager.layers[previousIndex].isCollapsed = false
                                    layerManager.layers[previousIndex].selectedReply = nil
                                    layerManager.layers[previousIndex].maskHeight = height
                                }
                            } else {
                                // Cancel the push.
                                withAnimation(.spring()) {
                                    layerManager.layers[previousIndex].isHidden = true
                                    layerManager.layers[previousIndex].maskHeight = previousLayer.baseHeight
                                }
                                
                                blurRadius = 0
                                scale = 1
                            }
                        }
                    }

                    // Push the current layer, pop all layers after.
                    if currentLayer.isCollapsed {
                        if shouldExpand {
                            // Expand the layer.
                            withAnimation(.spring()) {
                                // Pop all layers after the current one.
                                for i in stride(from: layerManager.layers.count - 1, through: index + 1, by: -1) {
                                    layerManager.popLayer(at: i)
                                }
                                layerManager.layers[index].isCollapsed = false
                                layerManager.layers[index].selectedReply = nil
                                layerManager.layers[index].maskHeight = height
                            } completion: {}
                        } else {
                            // Cancel the expansion.
                            withAnimation(.spring()) {
                                layerManager.layers[index].isHidden = true
                                layerManager.layers[index].maskHeight = currentLayer.baseHeight
                            }
                        }
                    }
                }
        )
    }
}

// MARK: LayerScrollViewWrapper

struct LayerScrollViewWrapper: UIViewControllerRepresentable {
    @Binding var scrollState: (phase: ScrollPhase, context: ScrollPhaseChangeContext)?
    @Binding var scrollDisabled: Bool
    @Binding var isOffsetAtTop: Bool
    @Binding var blurRadius: CGFloat
    @Binding var scale: CGFloat

    let width: CGFloat
    let height: CGFloat
    let index: Int
    let collapsedHeight: CGFloat
    let collapsedOffset: CGFloat
    let layerManager: LayerManager
    let layer: LayerManager.Layer
    let namespace: Namespace.ID

    func makeUIViewController(context: Context) -> UIHostingController<LayerScrollView> {
        let layerScrollView = LayerScrollView(
            scrollState: $scrollState,
            scrollDisabled: $scrollDisabled,
            isOffsetAtTop: $isOffsetAtTop,
            blurRadius: $blurRadius,
            scale: $scale,
            width: width,
            height: height,
            index: index,
            collapsedHeight: collapsedHeight,
            collapsedOffset: collapsedOffset,
            layerManager: layerManager,
            layer: layer,
            namespace: namespace
        )

        let hostingController = UIHostingController(rootView: layerScrollView)
        hostingController.view.backgroundColor = .clear
        hostingController.safeAreaRegions = []
        // hostingController.sizingOptions = .intrinsicContentSize
        return hostingController
    }

    func updateUIViewController(_ uiViewController: UIHostingController<LayerScrollView>, context: Context) {
        // Use the UIView extension to animate hidden state
        uiViewController.view.animateSetHidden(layer.isCollapsed,
                                               duration: 0.3)
    }

    typealias UIViewControllerType = UIHostingController<LayerScrollView>
}

// MARK: LayerScrollView

struct LayerScrollView: View {
    @EnvironmentObject private var windowState: WindowState
    @Binding var scrollState: (phase: ScrollPhase, context: ScrollPhaseChangeContext)?
    @Binding var scrollDisabled: Bool
    @Binding var isOffsetAtTop: Bool
    @Binding var blurRadius: CGFloat
    @Binding var scale: CGFloat

    let width: CGFloat
    let height: CGFloat
    let index: Int
    let collapsedHeight: CGFloat
    let collapsedOffset: CGFloat
    let layerManager: LayerManager
    let layer: LayerManager.Layer
    let namespace: Namespace.ID

    private var baseHeight: CGFloat {
        collapsedHeight + ((collapsedHeight / 1.75) * CGFloat(index))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(sampleComments) { reply in
                    ZStack {
                        ReplyView(reply: reply, isCollapsed: false)
                            .matchedGeometryEffect(id: reply.id, in: namespace)
                            .opacity(layer.selectedReply?.id == reply.id ? 0 : 1)
                            .onTapGesture {
                                withAnimation(.smooth) {
                                    layerManager.layers[index].selectedReply = reply
                                }
                                withAnimation(.spring()) {
                                    layerManager.layers[index].isCollapsed = true
                                    layerManager.layers[index].baseHeight = baseHeight
                                    layerManager.layers[index].maskHeight = baseHeight
                                    layerManager.pushLayer()
                                } completion: {
                                    layerManager.layers[index].isHidden = true
                                }
                            }
                    }
                }
            }
            .padding(24)
            .padding(.top, index == 0 ? 35.0 : 35.0 + (collapsedOffset * CGFloat(index)))
            .scaleEffect(scale)
            .animation(.spring(), value: scale)
        }
        .frame(minWidth: width, minHeight: height)
        .blur(radius: blurRadius) // Blur and scale are separate because scale breaks drag gesture.
        .animation(.spring(), value: blurRadius)
        .scrollDisabled(scrollDisabled)
        .onScrollPhaseChange { _, newPhase, context in
            scrollState = (newPhase, context)
        }
        .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
            geometry.contentOffset.y
        }, action: { _, newValue in
            if newValue <= 0 {
                index == 0 ? (windowState.isOffsetAtTop = true) : (isOffsetAtTop = true)
            } else if newValue > 0 {
                index == 0 ? (windowState.isOffsetAtTop = false) : (isOffsetAtTop = false)
            }
        })
    }
}

struct BottomLeftRightArcPath: InsettableShape {
    var cornerRadius: CGFloat
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Adjust the rect and corner radius based on the inset amount
        let adjustedRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let adjustedCornerRadius = cornerRadius - insetAmount

        // Bottom-left corner arc
        path.move(to: CGPoint(x: adjustedRect.minX, y: adjustedRect.maxY - adjustedCornerRadius))
        path.addArc(
            center: CGPoint(x: adjustedRect.minX + adjustedCornerRadius, y: adjustedRect.maxY - adjustedCornerRadius),
            radius: adjustedCornerRadius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 90),
            clockwise: true
        )

        // Bottom-right corner arc
        path.move(to: CGPoint(x: adjustedRect.maxX - adjustedCornerRadius, y: adjustedRect.maxY))
        path.addArc(
            center: CGPoint(x: adjustedRect.maxX - adjustedCornerRadius, y: adjustedRect.maxY - adjustedCornerRadius),
            radius: adjustedCornerRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 0),
            clockwise: true
        )

        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var newShape = self
        newShape.insetAmount += amount
        return newShape
    }
}

extension UIView {
    func animateSetHidden(_ hidden: Bool, duration: CGFloat = CATransaction.animationDuration(), completion: @escaping (Bool) -> () = { _ in }) {
        if duration > 0 {
            if self.isHidden, !hidden {
                self.alpha = 0
                self.isHidden = false
            }
            UIView.animate(withDuration: duration, delay: 0, options: .beginFromCurrentState) {
                self.alpha = hidden ? 0 : 1
            
            } completion: { c in
          
                if c {
                    self.isHidden = hidden
                }
                completion(c)
            }

        } else {
            self.isHidden = hidden
            self.alpha = hidden ? 0 : 1
            completion(true)
        }
    }
}
