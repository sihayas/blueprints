/// Thanks to this SO. https://stackoverflow.com/questions/25793141/continuous-vertical-scrolling-between-uicollectionview-nested-in-uiscrollview
import SwiftUI

#Preview {
    Home()
        .ignoresSafeArea()
}

struct Home: View {
    let viewSize = UIScreen.main.bounds.size

    @StateObject private var csvDelegate = CSVDelegate()
    @State var dragOffset: CGFloat = 0

    var body: some View {
        let innerBaseHeight: CGFloat = viewSize.height * 0.7
        let outerBaseHeight = viewSize.height - innerBaseHeight

        CSVRepresentable(delegate: csvDelegate) {
            ZStack(alignment: .top) {
                // MARK: - Below Scroll View

                InnerContent(
                    dragOffset: $dragOffset,
                    scrollDelegate: csvDelegate,
                    viewSize: viewSize,
                    innerBaseHeight: innerBaseHeight,
                    bottomSectionHeight: outerBaseHeight
                )

                // MARK: - Above Scroll View

                OuterContent(
                    dragOffset: $dragOffset,
                    innerBaseHeight: innerBaseHeight,
                    bottomSectionHeight: outerBaseHeight
                )
            }
            .frame( 
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
        }
        .onAppear {
            csvDelegate.viewSize = viewSize
            csvDelegate.innerBaseHeight = innerBaseHeight
            csvDelegate.outerBaseHeight = outerBaseHeight
        }
        .onChange(of: csvDelegate.dragOffset) { _, offset in
            withAnimation() {
                dragOffset = offset
            }
        }
    }
}

struct OuterContent: View {
    @Binding var dragOffset: CGFloat
    let innerBaseHeight: CGFloat
    let bottomSectionHeight: CGFloat
    
 
    // // Compute bounded offset for outer content
    // private var boundedOffset: CGFloat {
    //     // Start at upperSectionHeight (minimum)
    //     // Can increase up to upperSectionHeight + bottomSectionHeight (maximum)
    //     let minOffset: CGFloat = innerBaseHeight
    //     let maxOffset = innerBaseHeight + bottomSectionHeight
    //     return min(maxOffset, max(minOffset, innerBaseHeight + dragOffset))
    // }

    
    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                ForEach(0..<100) { _ in
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.clear)
                        .frame(height: 100)
                }
            }
            .background(.thinMaterial)
            .padding(.top, innerBaseHeight)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .top
        )
        .background(.clear)
        .padding(.bottom, innerBaseHeight)
        .offset(y: dragOffset)
    }
}

struct InnerContent: View {
    @Binding var dragOffset: CGFloat
    let scrollDelegate: CSVDelegate
    let viewSize: CGSize
    let innerBaseHeight: CGFloat
    let bottomSectionHeight: CGFloat

    private var boundedOffset: CGFloat {
        // Start at -bottomSectionHeight (minimum)
        // Can increase up to 0 (maximum)
        let minOffset = -bottomSectionHeight
        let maxOffset: CGFloat = 0
        return min(maxOffset, max(minOffset, -bottomSectionHeight + dragOffset))
    }
    
    let columns = [GridItem(.adaptive(minimum: 200), spacing: 16)]

    var body: some View {
        CSVRepresentable(isInner: true, delegate: scrollDelegate) {
            VStack(spacing: 1) {
                Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                    ForEach(1...4, id: \.self) { _ in
                        GridRow {
                            ForEach(1...3, id: \.self) { _ in
                                Color(white: 0.5 + Double.random(in: 0.0 ... 0.5), opacity: 1.0)
                            }
                        }
                    }
                }
                .aspectRatio(0.75, contentMode: .fit)
                Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                    ForEach(1...4, id: \.self) { _ in
                        GridRow {
                            ForEach(1...3, id: \.self) { _ in
                                Color(white: 0.5 + Double.random(in: 0.0 ... 0.5), opacity: 1.0)
                            }
                        }
                    }
                }
                .aspectRatio(0.75, contentMode: .fit)
                Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                    ForEach(1...4, id: \.self) { _ in
                        GridRow {
                            ForEach(1...3, id: \.self) { _ in
                                Color(white: 0.5 + Double.random(in: 0.0 ... 0.5), opacity: 1.0)
                            }
                        }
                    }
                }
                .aspectRatio(0.75, contentMode: .fit)
            }
        }
        .frame(height: viewSize.height)
        .offset(y: boundedOffset)
    }
}
