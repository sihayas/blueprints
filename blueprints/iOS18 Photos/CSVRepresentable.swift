//
//  CSVRepresentable.swift
//  acusia
//
//  Created by decoherence on 1/12/25.
//
/// Reverse engineering the iOS 18 Photos interface to understand
/// how Apple engineers approached removing tab bar based navigation.
/// Core idea is a single gesture recognizer controls 2 simultaneous scrollViews to create a uni-scroll effect. A bit buggy.
///
//  TODO: - Still needs extra polish and tweaking.
//        - Fix the weird rubberbanding on expand.
//        - Fix the un-collapse drag offset speed.


import SwiftUI

struct CSVRepresentable<Content: View>: UIViewRepresentable {
    let content: Content
    let isInner: Bool
    private let scrollDelegate: CSVDelegate

    init(isInner: Bool = false, delegate: CSVDelegate, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isInner = isInner
        self.scrollDelegate = delegate
    } 

    func makeUIView(context: Context) -> CSV {
        /// Create the CollaborativeScrollView in UIKit.
        let scrollView = CSV()
        scrollView.isInner = isInner
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = scrollDelegate
        scrollView.bounces = !isInner

        let hostController = UIHostingController(rootView: content)
        hostController.view.translatesAutoresizingMaskIntoConstraints = false
        hostController.view.backgroundColor = .clear
        hostController.safeAreaRegions = SafeAreaRegions()
        scrollView.addSubview(hostController.view)

        /// Constrain the SwiftUI content to the edges of the CollaborativeScrollView.
        NSLayoutConstraint.activate([
            hostController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        if isInner {
            scrollDelegate.innerScrollView = scrollView

            DispatchQueue.main.async {
                let bottomOffset = CGPoint(
                    x: 0,
                    y: scrollView.contentSize.height - scrollView.bounds.size.height
                )
                if bottomOffset.y > 0 {
                    scrollView.setContentOffset(bottomOffset, animated: false)
                }

                self.scrollDelegate.setupGestureRecognizers()
            }
        } else {
            // scrollView.isPagingEnabled = true
            scrollDelegate.outerScrollView = scrollView
        }

        return scrollView
    }

    func updateUIView(_ uiView: CSV, context: Context) {}
}

class CSVDelegate: NSObject, UIScrollViewDelegate, ObservableObject {
    @Published var isExpanded = false
    @Published var dragOffset: CGFloat = 0
    @Published var trackDragOffset = true
    @Published var previousTranslation: CGFloat = 0
    
    @Published var viewSize: CGSize = .zero
    @Published var innerBaseHeight: CGFloat = 0
    @Published var outerBaseHeight: CGFloat = 0

    private var lockOuterScrollView = false
    private var lockInnerScrollView = true
    private var initialDirection: Direction = .none

    weak var outerScrollView: CSV?
    weak var innerScrollView: CSV?

    enum Direction { case none, up, down }

    func setupGestureRecognizers() {
        guard let inner = innerScrollView, let outer = outerScrollView else { return }

        inner.otherPanGestureRecognizer = outer.panGestureRecognizer
        outer.otherPanGestureRecognizer = inner.panGestureRecognizer

        outer.addGestureRecognizer(inner.panGestureRecognizer)
    }
    
    func snapInnerToBottom() {
        guard let inner = innerScrollView else { return }
        
        let bottomOffset = CGPoint(
            x: 0,
            y: inner.contentSize.height - inner.bounds.size.height - outerBaseHeight
        )
        
        if bottomOffset.y > 0 {
            inner.setContentOffset(bottomOffset, animated: true)
        }
    }
            

    /// Lets the user begin expanding/collapsing. Unlocks scrolls if conditions are met.
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let csv = scrollView as? CSV else { return }
        csv.initialContentOffset = csv.contentOffset

        initialDirection = .none

        if !isExpanded {
            if csv === outerScrollView {
                if csv.contentOffset.y <= 0 {
                    /// If dragging starts at top of outer.
                    trackDragOffset = true
                    csv.bounces = false
                } else {
                    trackDragOffset = false
                    lockInnerScrollView = true
                    csv.bounces = true
                }
            }
        }

        /// If dragging starts at bottom of inner, unlock outer to allow collapse.
        if isExpanded {
            let isAtBottom = ((innerScrollView!.contentOffset.y + innerScrollView!.frame.size.height) >= innerScrollView!.contentSize.height)
            
            if isAtBottom {
                lockOuterScrollView = false
            } else {
                trackDragOffset = false
                lockOuterScrollView = true
            }
        }
    }

    /// Decides if we commit to expanded or collapsed based on final scroll position.
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        guard let csv = scrollView as? CSV else { return }
 
        /// Expand and drop lock if the drag gesture was large enough to allow scrolling.
        if !isExpanded, csv === innerScrollView {
            if dragOffset > 0 {
                trackDragOffset = false
                isExpanded = true
                dragOffset = outerBaseHeight
                lockInnerScrollView = dragOffset <= 32
                csv.bounces = true
            }
        } 
 
        /// Collapse if user scrolled outer (means they want to go back).
        if isExpanded, csv === outerScrollView {
            if csv.contentOffset.y > 0 {
                trackDragOffset = true
                isExpanded = false
                dragOffset = 0
                innerScrollView?.bounces = false
            }
        }
    }

    /// Cleanup post-drag. Good place to snap locked scroll offsets if needed.
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {}

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {}

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}

    private var lastTranslationY: CGFloat = 0

    /// Core logic that locks/unlocks outer and inner scrolls depending on state and direction.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let csv = scrollView as? CSV else { return }
        let direction: Direction = csv.lastContentOffset.y > csv.contentOffset.y ? .up : .down
         
        /// ABORT based on initial direction.
        if initialDirection == .none && csv.contentOffset.y != csv.initialContentOffset.y {
            initialDirection = csv.contentOffset.y > csv.initialContentOffset.y ? .down : .up
        }
         
        /// Track pan gesture at rest.
        if trackDragOffset {
            if dragOffset >= outerBaseHeight {
                lockInnerScrollView = false
            }
             
            let translationY = csv.panGestureRecognizer.translation(in: csv).y
            let delta = translationY - lastTranslationY
  
            if isExpanded {
                dragOffset = max(0, dragOffset + delta)
            } else {
                dragOffset = max(0, min(outerBaseHeight, translationY))
            }

            lastTranslationY = translationY
             
            print("Drag offset: \(dragOffset)")
        }

        /// Lock outer: force offset to top and hide indicator.
        if lockOuterScrollView {
            outerScrollView!.contentOffset = CGPoint(x: 0, y: 0)
            outerScrollView!.showsVerticalScrollIndicator = false
        }

        /// Lock inner: force offset to bottom and hide indicator.
        if lockInnerScrollView {
            innerScrollView!.contentOffset.y = innerScrollView!.contentSize.height - innerScrollView!.bounds.size.height
        }


        if !isExpanded {
            /// Abort expansion if user drags downward immediately. Works in tandom with
            /// `scrollViewWillBeginDragging`.
            if initialDirection == .down {
                lockInnerScrollView = true
                trackDragOffset = false
            }
 
            if csv === innerScrollView {
                let isAtBottom = (csv.contentOffset.y + csv.frame.size.height) >= csv.contentSize.height
                
                /// Expansion logic
                if !lockInnerScrollView {
                    if direction == .up && outerScrollView?.contentOffset.y ?? 0 <= 0 {
                        lockOuterScrollView = true
                    } else if direction == .down && isAtBottom {
                        lockOuterScrollView = false
                    }
                }
            }
        }

        if isExpanded {
            /// Abort collapse if user scrolls upward immediately. Works in tandom with `scrollViewWillBeginDragging`.
            if initialDirection == .up {
                print("aborting collapse")
                lockOuterScrollView = true
                trackDragOffset = false
            }
 
            if csv === innerScrollView {
                let isAtBottom = (csv.contentOffset.y + csv.frame.size.height) >= csv.contentSize.height

                /// Collapse logic
                if !lockOuterScrollView {
                    if direction == .down && isAtBottom {
                        lockInnerScrollView = true
                    } else if direction == .up && outerScrollView?.contentOffset.y ?? 0 <= 0 {
                        lockOuterScrollView = true
                    }
                }
            }
            
        }

        csv.lastContentOffset = csv.contentOffset
    }
}


class CSV: UIScrollView, UIGestureRecognizerDelegate {
    var lastContentOffset: CGPoint = .zero
    var initialContentOffset: CGPoint = .zero
    var isInner: Bool = false

    /// Add reference to the other scroll view's gesture recognizer
    var otherPanGestureRecognizer: UIPanGestureRecognizer?

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        /// Make sure we're the delegate for our own pan gesture recognizer
        panGestureRecognizer.delegate = self
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        /// Allow simultaneous recognition with the other scroll view's gesture
        if otherGestureRecognizer == otherPanGestureRecognizer {
            return true
        }
        return false
    }
}
