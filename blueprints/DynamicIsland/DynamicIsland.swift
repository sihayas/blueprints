//
//  DynamicIsland.swift
//  blueprints
//
//  Created by decoherence on 3/28/25.
//
import SwiftUI

enum Field: Hashable {
    case search
    case reply
}

#Preview {
    let uiState = UIState.shared
    
    ZStack(alignment: .bottom) {
        VStack {
            Image("ramp")
                .resizable()
                .scaledToFit()
                .clipShape(Capsule())
        }
        .frame( maxHeight: 32)
        
        SymmetryView()
            .environmentObject(uiState)
            .onAppear {
                uiState.enableDarkMode()
            }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}

struct SymmetryView: View {
    @EnvironmentObject private var uiState: UIState
    @FocusState var focusedField: Field?
    
    // MARK: Appear State

    @State var symmetryState = SymmetryState(
        leading: .init(
            showContent: false,
            offset: .zero,
            size: CGSize(width: 128, height: 40)
        ),
        center: .init(
            showContent: false,
            offset: .zero,
            size: CGSize(width: 128, height: 40)
        ),
        trailing: .init(
            showContent: false,
            offset: .zero,
            size: CGSize(width: 128, height: 40)
        )
    )
    
    /// Canvas Properties
    @State private var width: CGFloat = 0
    @State private var height: CGFloat = 0
    @State private var centerWidth: CGFloat = 0
    @State private var blurRadius: CGFloat = 4
    
    /// Center Capsule Properties
    @State var replyText: String = ""
    @State var replySize: CGSize = .zero
     
    /// Constants
    let baseHeight: CGFloat = 44
    let baseWidth: CGFloat = 128
    let baseRadius: CGFloat = 22
    
    let horizontalPadding: CGFloat = 48
    let gap: CGFloat = 18
    
    @State private var isAutoCycling = true
    let cycleDelay: TimeInterval = 0.35
    
    var body: some View {
        GeometryReader { geometry in
            let centerPoint = CGPoint(x: width / 2, y: height / 2)
            
            ZStack {
                // MARK: Canvas

                Rectangle()
                    .background(.thinMaterial)
                    .foregroundStyle(.clear)
                    .mask {
                        Canvas { ctx, _ in
                            let leading = ctx.resolveSymbol(id: 0)!
                            let trailing = ctx.resolveSymbol(id: 1)!
                            let center = ctx.resolveSymbol(id: 2)!
                            
                            ctx.addFilter(.alphaThreshold(min: 0.5))
                            ctx.addFilter(.blur(radius: blurRadius))
                            
                            ctx.drawLayer { ctx1 in
                                ctx1.draw(leading, at: centerPoint)
                                ctx1.draw(trailing, at: centerPoint)
                                ctx1.draw(center, at: centerPoint)
                            }
                        } symbols: {
                            createSymbol(
                                shape: RoundedRectangle(cornerRadius: symmetryState.leading.cornerRadius, style: .continuous),
                                fillColor: .black,
                                overlayContent: EmptyView(),
                                size: symmetryState.leading.size,
                                offset: symmetryState.leading.offset,
                                width: width,
                                height: height,
                                tag: 0
                            )

                            createCenterSymbol(
                                fillColor: .black,
                                overlayContent: EmptyView(),
                                width: width,
                                height: height,
                                tag: 1
                            )
                            
                            createSymbol(
                                shape: RoundedRectangle(cornerRadius: symmetryState.trailing.cornerRadius, style: .continuous),
                                fillColor: .black,
                                overlayContent: EmptyView(),
                                size: symmetryState.trailing.size,
                                offset: symmetryState.trailing.offset,
                                width: width,
                                height: height,
                                tag: 2
                            )
                        }
                    }
                    .allowsHitTesting(false)
                
                // MARK: Overlay

                Group {
                    createSymbol(
                        shape: RoundedRectangle(cornerRadius: symmetryState.leading.cornerRadius, style: .continuous),
                        fillColor: .clear,
                        overlayContent:
                        ZStack {
                            if uiState.symmetryState == .feed {
                                // AvatarView(size: 40, imageURL: "https://i.pinimg.com/474x/36/21/cb/3621cbc3ccededfd4591ff199aa0ef0d.jpg")
                                //     .background(Color.gray.opacity(0.001))
                                //     .onTapGesture {
                                //         uiState.symmetryState = .user
                                //     }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(symmetryState.leading.showContent ? 1 : 0)
                        .animation(nil, value: symmetryState.leading.showContent),
                        size: symmetryState.leading.size,
                        offset: symmetryState.leading.offset,
                        width: width,
                        height: height,
                        tag: 0
                    )
                    
                    createCenterSymbol(
                        fillColor: .clear,
                        overlayContent:
                        ZStack {}
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(symmetryState.center.showContent ? 1 : 0)
                            .animation(nil, value: symmetryState.center.showContent),
                        width: width,
                        height: height,
                        tag: 1
                    )
                    
                    createSymbol(
                        shape: RoundedRectangle(cornerRadius: symmetryState.trailing.cornerRadius, style: .continuous),
                        fillColor: .clear,
                        overlayContent:
                        ZStack {}
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(symmetryState.trailing.showContent ? 1 : 0)
                            .animation(nil, value: symmetryState.trailing.showContent),
                        size: symmetryState.trailing.size,
                        offset: symmetryState.trailing.offset,
                        width: width,
                        height: height,
                        tag: 2
                    )
                }
                
                // ControlButtons()
            }
            .onAppear {
                self.width = geometry.size.width
                self.height = geometry.size.height
                self.centerWidth = geometry.size.width / 2
                
                uiState.symmetryState = .reply
            }
            .onChange(of: uiState.symmetryState) { _, _ in
                switch uiState.symmetryState {
                case .collapsed:
                    resetState()
                case .feed:
                    feedState()
                case .reply:
                    replyState()
                }
            }
            .onChange(of: uiState.symmetryState) { _, newState in
                           // This reaction logic remains the same
                           switch newState {
                           case .collapsed:
                               resetState()
                           case .feed:
                               feedState()
                           case .reply:
                               replyState()
                           }
                       }
                       // --- Add the .task modifier ---
                       .task(id: isAutoCycling) { // Restart this task if isAutoCycling changes
                           guard isAutoCycling else {
                               // If cycling is turned off, cancel any ongoing delay and exit
                               return
                           }

                           // Ensure we start cleanly from reset if auto-cycling is turned on
                           await MainActor.run { uiState.symmetryState = .collapsed }

                           do {
                               // Infinite loop while auto-cycling is enabled
                               while !Task.isCancelled {
                                   // Sequence: reset -> wait -> feed -> wait -> reset -> wait -> reply -> wait -> (loop)

                                   // 1. Currently in .reset (or just finished reply) -> Wait
                                   try await Task.sleep(for: .seconds(cycleDelay))
                                   guard !Task.isCancelled else { break }

                                   // 2. Transition to .feed
                                   await MainActor.run { uiState.symmetryState = .feed }
                                   // Wait after .feed
                                   try await Task.sleep(for: .seconds(cycleDelay))
                                   guard !Task.isCancelled else { break }

                                   // 3. Transition to .reset
                                   await MainActor.run { uiState.symmetryState = .collapsed }
                                   // Wait after .reset
                                   try await Task.sleep(for: .seconds(cycleDelay))
                                   guard !Task.isCancelled else { break }

                                   // 4. Transition to .reply
                                   await MainActor.run { uiState.symmetryState = .reply }
                                   // Wait after .reply (before looping back to step 1)
                                   try await Task.sleep(for: .seconds(cycleDelay))
                                   guard !Task.isCancelled else { break }
                                   
                                   // 5. Transition back to .reset to complete the reply->reset part of the cycle
                                   await MainActor.run { uiState.symmetryState = .collapsed }
                                   // Wait after .reset (before looping back to step 1 which transitions to feed)
                                   // The next Task.sleep at the *start* of the loop handles the delay *after* this reset.

                                   // Loop continues...
                               }
                           } catch is CancellationError {

                               print("Auto-cycle task cancelled.")
                           } catch {

                               print("Auto-cycle task failed: \(error)")
                           }
                       }
        }
    }
}

// MARK: View Builders

extension SymmetryView {
    func createSymbol<ShapeType: Shape, Content: View>(
        shape: ShapeType,
        fillColor: Color,
        overlayContent: Content,
        size: CGSize,
        offset: CGPoint,
        width: CGFloat,
        height: CGFloat,
        tag: Int
    ) -> some View {
        shape
            .fill(fillColor)
            .frame(width: size.width, height: size.height)
            .overlay(overlayContent)
            .offset(x: offset.x, y: offset.y)
            .frame(width: width, height: height, alignment: .bottom)
            .tag(tag)
    }
    
    func createCenterSymbol<Content: View>(
        fillColor: Color,
        overlayContent: Content,
        width: CGFloat,
        height: CGFloat,
        tag: Int
    ) -> some View {
        VStack(spacing: 0) {
            Group {
                TextEditor(text: $replyText)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .padding([.top, .horizontal], 8)
                    .focused($focusedField, equals: .reply)
                    .focused($focusedField, equals: .search)
                    .textEditorBackground(.clear)
                 
                // if uiState.symmetryState == .reply {
                //     HStack {
                //         Button(action: {
                //             print("context menu")
                //         }) {
                //             Image(systemName: "plus")
                //                 .contentTransition(.symbolEffect(.replace))
                //                 .foregroundColor(.secondary)
                //                 .animation(.smooth, value: replyText.isEmpty)
                //                 .font(.system(size: 18))
                //         }
                //         .padding(.horizontal, 4)
                //
                //         Spacer()
               
                //         Button(action: {
                //             replyText.isEmpty ? print("hi") : print("send")
                //         }) {
                //             Image(systemName: replyText.isEmpty ? "xmark.circle.fill" : "arrow.up.circle.fill")
                //                 .contentTransition(.symbolEffect(.replace))
                //                 .foregroundColor(replyText.isEmpty ? .white : .white)
                //                 .animation(.smooth, value: replyText.isEmpty)
                //                 .font(.system(size: 27))
                //         }
                //     }
                //     .padding([.horizontal, .bottom], 8)
                // }
            }
            .opacity(uiState.symmetryState != .reply ? 0 : 1)
        }
        .frame(width: symmetryState.center.size.width)
        .frame(minHeight: symmetryState.center.size.height)
        .background(fillColor, in: RoundedRectangle(cornerRadius: symmetryState.center.cornerRadius, style: .continuous))
        .measure($replySize)
        .frame(maxHeight: 180)
        .fixedSize(horizontal: false, vertical: true)
        .overlay(overlayContent)
        .offset(x: symmetryState.center.offset.x, y: symmetryState.center.offset.y)
        .frame(width: width, height: height, alignment: .bottom)
        .tag(tag)
    }
}

// MARK: Control Buttons

extension SymmetryView {
    func resetState() {
        withAnimation(.interpolatingSpring(
            mass: 1.0,
            stiffness: pow(2 * .pi / 0.5, 2),
            damping: 4 * .pi * 0.7 / 0.5,
            initialVelocity: 0.0
        )) {
            focusedField = nil
            replyText = ""
            blurRadius = 4
            symmetryState = SymmetryState(
                leading: .init(
                    showContent: false,
                    offset: .zero,
                    size: CGSize(width: baseWidth, height: baseHeight),
                    cornerRadius: baseRadius
                ),
                center: .init(
                    showContent: false,
                    offset: .zero,
                    size: CGSize(width: baseWidth, height: baseHeight),
                    cornerRadius: baseRadius
                ),
                trailing: .init(
                    showContent: false,
                    offset: .zero,
                    size: CGSize(width: baseWidth, height: baseHeight),
                    cornerRadius: baseRadius
                )
            )
        } completion: {
            blurRadius = 0
        }
    }
    
    /// Move the leading capsule to the left & shrink
    /// Show the center capsule content, content is FeedState
    /// Move the trailing capsule to the right a bit for symmetry
    func feedState() {
        withAnimation(.interpolatingSpring(
            mass: 1.0,
            stiffness: pow(2 * .pi / 0.5, 2),
            damping: 4 * .pi * 0.7 / 0.5,
            initialVelocity: 0.0
        )) {
            focusedField = nil
            blurRadius = 4
            symmetryState = SymmetryState(
                leading: .init(
                    showContent: true,
                    offset: CGPoint(x: -centerWidth + 20 + 32, y: 0),
                    size: CGSize(width: baseHeight, height: baseHeight)
                ),
                center: .init(
                    showContent: true,
                    offset: .zero,
                    size: CGSize(width: baseWidth, height: baseHeight),
                    cornerRadius: baseRadius
                ),
                trailing: .init(
                    showContent: true,
                    offset: CGPoint(x: centerWidth - 20 - 32, y: 0),
                    size: CGSize(width: baseHeight, height: baseHeight)
                )
            )
        } completion: {
            blurRadius = 0
        }
    }
    
    /// Move the trailing capsule to the right & expand
    /// Move the leading capsule to the left, shrink
    /// Show the center capsule up, content is the selected result.
    func replyState() {
        withAnimation(.interpolatingSpring(
            mass: 1.0,
            stiffness: pow(2 * .pi / 0.5, 2),
            damping: 4 * .pi * 0.7 / 0.5,
            initialVelocity: 0.0
        )) {
            let height: CGFloat = 80
            
            blurRadius = 4
            focusedField = .reply
            symmetryState = SymmetryState(
                leading: .init(
                    showContent: false,
                    offset: .zero,
                    size: CGSize(
                        width: width - horizontalPadding,
                        height: height
                    )
                ),
                center: .init(
                    showContent: true,
                    offset: .zero,
                    size: CGSize(
                        width: width - horizontalPadding,
                        height: height
                    ),
                    cornerRadius: baseRadius
                ),
                trailing: .init(
                    showContent: false,
                    offset: .zero,
                    size: CGSize(
                        width: width - horizontalPadding,
                        height: height
                    )
                )
            )
        } completion: {
            blurRadius = 0
        }
    }
}

struct ControlButtons: View {
    // MARK: Buttons

    @EnvironmentObject private var uiState: UIState
    
    var body: some View {
       
            HStack {
                Button(action: {
                    uiState.symmetryState = .feed
                }) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button(action: {
                    uiState.symmetryState = .collapsed
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button(action: {
                    uiState.symmetryState = .reply
                }) {
                    Image(systemName: "arrowshape.turn.up.right.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
      
    }
}

private func viewHeight(for binding: Binding<CGFloat>) -> some View {
    GeometryReader { geometry -> Color in
        let rect = geometry.frame(in: .local)

        DispatchQueue.main.async {
            binding.wrappedValue = rect.size.height
        }
        return .clear
    }
}

extension View {
    func textEditorBackground(_ content: Color) -> some View {
        if #available(iOS 16.0, *) {
            return self.scrollContentBackground(.hidden)
                .background(content)
        } else {
            UITextView.appearance().backgroundColor = .clear
            return background(content)
        }
    }
}
