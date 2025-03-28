//
//  SwivelView.swift
//  blueprints
//
//  Created by decoherence on 3/18/25.
//

import SwiftUI

struct IntroPageItem: Identifiable {
    var id: String = UUID().uuidString
    var image: String
    var title: String
    
    /// Locations
    var scale: CGFloat = 1
    var anchor: UnitPoint = .center
    var offset: CGFloat = 0
    var rotation: CGFloat = 0
    var zindex: CGFloat = 0
    /// As you can observe, the ZIndex won’t have any animation effects. Therefore, I’ll modify the offset value when it starts moving and reset its original offset value after a slight delay. This will ultimately make the icons appear to be swapping.
    /// Update this as per your needs
    var extraOffset: CGFloat = -350
    var description: String
}

/// Intro Page Items
let staticIntroItems: [IntroPageItem] = [
    .init(
        image: "one",
        title: "The Let Them Theory",
        scale: 1,
        description: "Mel Robbins"
    ),
    .init(
        image: "two",
        title: "Catching Fire",
        scale: 0.6,
        anchor: .topLeading,
        offset: -110,
        rotation: 30,
        description: "Suzanne Collins"
    ),
    .init(
        image: "three",
        title: "The Next Conversation",
        scale: 0.5,
        anchor: .bottomLeading,
        offset: -100,
        rotation: -35,
        description: "Jefferson Fisher"
    ),
    .init(
        image: "four",
        title: "Onyx Storm",
        scale: 0.4,
        anchor: .bottomLeading,
        offset: -100,
        rotation: 160,
        extraOffset: -120,
        description: "Rebecca Yaros"
    ),
    .init(
        image: "five",
        title: "The Tell",
        scale: 0.35,
        anchor: .bottomLeading,
        offset: -100,
        rotation: 250,
        extraOffset: -100,
        description: "Amy Griffin"
    )
]

struct IntroPageView: View {
    /// View Properties
    @State private var selectedItem: IntroPageItem = staticIntroItems.first!
    @State private var introItems: [IntroPageItem] = staticIntroItems
    @State private var activeIndex: Int = 0
    @State private var askUsername: Bool = false
    @AppStorage("username") private var username: String = ""
    @AppStorage("isIntroCompleted") private var isIntroCompleted: Bool = false
    
    var body: some View {
        /// Now Let's Start Building the actual Intro Page UI
        VStack(spacing: 0) {
            /// Back Button
            Button {
                updateItem(isForward: false)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(.green.gradient)
                    .contentShape(.rect)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            /// Only Visible from second item
            .opacity(selectedItem.id != introItems.first?.id ? 1 : 0)
            
            ZStack {
                /// Animated Icons
                ForEach(introItems) { item in
                    AnimatedIconView(item)
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
            
            VStack(spacing: 6) {
                /// Progress Indicator View
                HStack(spacing: 4) {
                    ForEach(introItems) { item in
                        Capsule()
                            .fill((selectedItem.id == item.id ? Color.pink : .gray).gradient)
                            .frame(width: selectedItem.id == item.id ? 25 : 4, height: 4)
                    }
                }
                .padding(.bottom, 15)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedItem.title)
                            .font(.title.bold())
                            .contentTransition(.numericText())
                            .multilineTextAlignment(.leading)
                         
                        /// YOUR CUSTOM DESCRIPTION HERE
                        Text(selectedItem.description)
                            .contentTransition(.numericText())
                            .font(.caption2)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    /// Next/Continue Button
                    Button {
                        if selectedItem.id == introItems.last?.id {
                            /// Continue Button Pressed
                            resetIntro()
                        } else {
                            updateItem(isForward: true)
                        }
                        
                    } label: {
                        Image(systemName: selectedItem.id == introItems.last?.id ? "reset" : "chevron.right")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .padding(12)
                            .background(.pink.gradient, in: .circle)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .multilineTextAlignment(.center)
            .frame(maxHeight: .infinity)
            .padding(.horizontal)
        }
        .ignoresSafeArea(.keyboard, edges: .all)
    }
    
    @ViewBuilder
    func AnimatedIconView(_ item: IntroPageItem) -> some View {
        let isSelected = selectedItem.id == item.id
        
        Image(item.image)
            .resizable()
            .scaledToFill()
            .font(.system(size: 80))
            .foregroundStyle(.white)
            // .blendMode(.overlay)
            .frame(width: 240, height: 240)
            .background(.black, in: .rect(cornerRadius: 32))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 35)
                    .fill(.background)
                    .padding(-3)
                    .opacity(selectedItem.id == item.id ? 1 : 0)
            }
            /// Resetting Rotation
            .rotationEffect(.init(degrees: -item.rotation))
            .scaleEffect(isSelected ? 1.1 : item.scale, anchor: item.anchor)
            .offset(x: item.offset)
            .rotationEffect(.init(degrees: item.rotation))
            /// Placing active icon at the top
            .zIndex(isSelected ? 2 : item.zindex)
    }
    
    func resetIntro() {
        Task {
            withAnimation(.bouncy(duration: 1)) {
                for index in introItems.indices {
                    introItems[index].scale = staticIntroItems[index].scale
                    introItems[index].rotation = staticIntroItems[index].rotation
                    introItems[index].anchor = staticIntroItems[index].anchor
                    introItems[index].offset = staticIntroItems[index].offset
                    introItems[index].zindex = 0
                }
            }
            
            try? await Task.sleep(for: .seconds(0.1))

            withAnimation(.bouncy(duration: 0.9)) {
                activeIndex = 0
                selectedItem = introItems[activeIndex]
            }
        }
    }
    
    /// Let's shift active icon to the center when continue or back button is pressed
    func updateItem(isForward: Bool) {
        /// Now let's implement backwards interaction as well
        guard isForward ? activeIndex != introItems.count - 1 : activeIndex != 0 else {
            return
        }
        
        var fromIndex: Int
        var extraOffset: CGFloat
        /// To Index
        if isForward {
            activeIndex += 1
        } else {
            activeIndex -= 1
        }
        /// From Index
        if isForward {
            fromIndex = activeIndex - 1
            extraOffset = introItems[activeIndex].extraOffset
        } else {
            extraOffset = introItems[activeIndex].extraOffset
            fromIndex = activeIndex + 1
        }
        
        /// Resetting ZIndex
        for index in introItems.indices {
            introItems[index].zindex = 0
        }
        
        /// Swift 6 Error
        Task { [fromIndex, extraOffset] in
            /// Shifting from and to icon locations
            withAnimation(.bouncy(duration: 1)) {
                introItems[fromIndex].scale = introItems[activeIndex].scale
                introItems[fromIndex].rotation = introItems[activeIndex].rotation
                introItems[fromIndex].anchor = introItems[activeIndex].anchor
                introItems[fromIndex].offset = introItems[activeIndex].offset
                /// Temporary Adjustment
                introItems[activeIndex].offset = extraOffset
                /// The moment selected item is updated, it pushes the from card all the way to the back in terms of the zIndex
                /// To solve this we can make use of Zindex property to just place the from card below the to card
                /// EG: To card Postion: 2
                /// From Card Postion: 1
                /// Others 0
                introItems[fromIndex].zindex = 1
            }
            
            try? await Task.sleep(for: .seconds(0.1))
            
            withAnimation(.bouncy(duration: 0.9)) {
                /// To location is always at the center
                introItems[activeIndex].scale = 1
                introItems[activeIndex].rotation = .zero
                introItems[activeIndex].anchor = .center
                introItems[activeIndex].offset = .zero
                
                /// Updating Selected Item
                selectedItem = introItems[activeIndex]
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        ScrollView {
            IntroPageView()
                .transition(.move(edge: .leading))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
