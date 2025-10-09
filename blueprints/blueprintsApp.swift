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
                BontentView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(WindowState.shared)
        }
    }
}

import SwiftUI

struct BontentView: View {
    @State private var selectedPreview: PreviewType? = nil
    @State private var placeholderText: String = "blueprints"
    @Namespace private var ns

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text(placeholderText)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundColor(.gray.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .contentTransition(.numericText())

                Spacer()

                ForEach(PreviewType.allCases, id: \.self) { preview in
                    Button {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            placeholderText = preview.title
                        }
                        selectedPreview = preview
                    } label: {
                        ChatCell(type: preview.icon, title: preview.title)
                    }
                    .buttonStyle(
                        FluidZoomTransitionButtonStyle(
                            id: preview.id,
                            namespace: ns,
                            shape: Capsule(),
                            glass: .identity
                        )
                    )
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
            .sheet(item: $selectedPreview, onDismiss: {
                withAnimation(.easeInOut(duration: 0.28)) {
                    placeholderText = "blueprints"
                }
            }) { preview in
                ZStack {
                    preview.destination
                        .environmentObject(UIState.shared)
                        .environmentObject(WindowState.shared)
                        .navigationTransition(.zoom(sourceID: preview.id, in: ns))

                    DescriptionOverlay(text: preview.description)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
                .interactiveDismissDisabled(preview == .home)
            }
        }
    }
}

struct DescriptionOverlay: View {
    let text: String
    @State private var isVisible: Bool = true

    var body: some View {
        if isVisible {
            VStack {
                VStack(spacing: 8) {
                    Text("Tap to dismiss")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text(text)
                        .font(.body)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
                .padding(.vertical, 16)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isVisible = false
                }
            }
        }
    }
}

enum PreviewType: String, CaseIterable, Identifiable {
    case symmetry, imprint, sound, holo, circlify, cards, flip, replies, vc, home

    var id: String { rawValue }

    var title: String {
        switch self {
        case .symmetry: return "Symmetry View"
        case .imprint: return "Imprint Preview"
        case .sound: return "Sound Scene"
        case .holo: return "Holo Preview"
        case .circlify: return "Circlify Demo"
        case .cards: return "Card Deck"
        case .flip: return "Flip Controller"
        case .replies: return "Replies"
        case .vc: return "VC Preview"
        case .home: return "Home"
        }
    }

    var icon: String {
        switch self {
        case .symmetry: return "square.split.2x1"
        case .imprint: return "paintpalette"
        case .sound: return "waveform"
        case .holo: return "sparkles"
        case .circlify: return "circle.grid.cross"
        case .cards: return "rectangle.portrait.on.rectangle.portrait"
        case .flip: return "arrow.2.circlepath"
        case .home: return "house"
        case .replies: return "bubble.left.and.bubble.right"
        case .vc: return "rectangle.and.text.magnifyingglass"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .symmetry:
            SymmetryView()
        case .imprint:
            ImprintPreview()
        case .sound:
            SoundScreen(
                sound: APIAppleSoundData(
                    id: "1",
                    type: "song",
                    name: "Song Name",
                    artistName: "Artist Name",
                    albumName: "Album Name",
                    releaseDate: "2022-01-01",
                    artworkUrl: "https://example",
                    artworkBgColor: "#000000",
                    identifier: "123",
                    trackCount: 1
                )
            )
        case .holo:
            HoloPreview()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
        case .circlify:
            CirclifyDemoView()
        case .cards:
            TiltingCardDeckPreview()
        case .flip:
            FlipViewControllerPreview()
                .ignoresSafeArea()
        case .replies:
            RepliesSheet(size: UIScreen.main.bounds.size, minHomeHeight: 32)
                .environmentObject(WindowState.shared)
        case .vc:
            ViewControllerPreview(
                viewController: UINavigationController(rootViewController: CollectionViewController())
            )
            .edgesIgnoringSafeArea(.all)
        case .home:
            Home()
                .ignoresSafeArea()
        }
    }

    var description: String {
        switch self {
        case .symmetry:
            return "A morphic, dynamic-island-inspired canvas view using blur and metaball effects to create fluid organic motion."
        case .imprint:
            return "An interactive album rating prototype. Swipe right to love, left to dislike. Tap the heart when it settles to reset. Built with custom morphing vectors and modern animation APIs."
        case .sound:
            return "A SceneKit and Metal experiment rendering an iridescent ellipsoid that shifts color based on its index of refraction. The IOR value changes the tint, while the text modifies the engraved surface using a normal map generated in real time with Core Image filters."
        case .holo:
            return "A holographic sticker effect driven by Metal shaders, producing vibrant reflective color shifts for a striking look. Tilt or drag the device up and down to see the iridescent effect change dynamically."
        case .circlify:
            return "A Swift reimplementation of the Circlify Python package that packs hierarchical data into nested non-overlapping circles."
        case .cards:
            return "Swipable, tilt-reactive cards inspired by BigUIPaging. Cards rotate slightly along the Z-axis for a natural 3D feel without clipping artifacts."
        case .flip:
            return "A 1:1 recreation of Metro UI’s turnstile_in animation. Tap a cell to see it flip in 3D space, anchored to the container’s center for accurate perspective."
        case .replies:
            return "A vertical threading concept inspired by early Threads prototypes. Tap a message to pull it into focus at the top, and drag down on collapsed threads to restore context."
        case .vc:
            return "A minimal zoom transition between UIKit view controllers that demonstrates seamless view-to-VC presentation."
        case .home:
            return "A uni-view navigation prototype that replaces tab hierarchies. Scroll up and down to trigger bounce transitions, then drag down from the top to reveal the nested inner view. Inspired by iOS 18 Photos."
        }
    }
}

#Preview {
    BontentView()
}

struct FluidZoomTransitionButtonStyle<S: Shape>: ButtonStyle {
    var id: String
    var namespace: Namespace.ID
    var shape: S
    var glass: Glass

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .matchedTransitionSource(id: id, in: namespace)
            .glassEffect(glass.interactive(), in: shape)
    }
}

struct ChatCell: View {
    let type: String
    let title: String

    var body: some View {
        Capsule(style: .continuous)
            .strokeBorder(.black.opacity(0.15), lineWidth: 1)
            .fill(.clear)
            .frame(maxWidth: .infinity, maxHeight: 48)
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: -3)
            .overlay {
                HStack {
                    Image(systemName: type)
                        .padding(.leading, 16)
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
    }
}

#Preview {
    BontentView()
}
