//
//  CustomCollectionTransition.swift
//
//  A single-file example of a custom push transition in UIKit
//  with a SwiftUI Preview Canvas.
//
//  Created by ChatGPT on 2025-05-07.
//

import UIKit
import SwiftUI

// MARK: - Rounded Collection View Cell

class RoundedCell: UICollectionViewCell {
    static let reuseIdentifier = "RoundedCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemBlue
        contentView.layer.cornerRadius = 32
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Detail View Controller

class ZoomDetailViewController: UIViewController {
    let cellColor: UIColor

    init(cellColor: UIColor) {
        self.cellColor = cellColor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = cellColor
        view.layer.cornerRadius = 55
        view.layer.cornerCurve = .continuous
    }
}

// MARK: - Custom Push Animator

class PushAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var selectedCellSnapshot: UIView?
    var selectedCellInitialFrame: CGRect = .zero
    let duration: TimeInterval = 0.6
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from) as? CollectionViewController,
            let toVC = transitionContext.viewController(forKey: .to),
            let selectedIndexPath = fromVC.selectedIndexPath
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        // Apply perspective to container for 3D cell rising
        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 250.0
        containerView.layer.sublayerTransform = perspective
        let finalFrame = transitionContext.finalFrame(for: toVC)
        
        // Prepare toVC
        toVC.view.frame = finalFrame
        containerView.addSubview(toVC.view)
        toVC.view.alpha = 1
        
        // Use UIView mask for cleaner corner animation
        let maskInitialFrame = selectedCellInitialFrame.offsetBy(dx: -finalFrame.origin.x, dy: -finalFrame.origin.y)
        let maskView = UIView(frame: maskInitialFrame)
        maskView.backgroundColor = .black
        maskView.layer.cornerRadius = 32
        maskView.layer.cornerCurve = .continuous
        toVC.view.mask = maskView

        // Animate mask expansion with UIViewPropertyAnimator
        let maskDuration: TimeInterval = duration + 0.3
        let animator = UIViewPropertyAnimator(duration: maskDuration, dampingRatio: 0.85) {
            maskView.frame = toVC.view.bounds
            maskView.layer.cornerRadius = toVC.view.layer.cornerRadius
        }
        animator.addCompletion { _ in
            toVC.view.mask = nil
        }
        animator.startAnimation()
        
        
        // Hide original cells & create snapshots
        let allCells = fromVC.collectionView.visibleCells
        var otherSnapshots: [UIView] = []
        for cell in allCells {
            guard let idx = fromVC.collectionView.indexPath(for: cell),
                  idx != selectedIndexPath else { continue }
            let snap = cell.snapshotView(afterScreenUpdates: false)!
            snap.frame = containerView.convert(cell.frame, from: fromVC.collectionView)
            containerView.addSubview(snap)
            otherSnapshots.append(snap)
            cell.isHidden = true
        }
        
        // Animate untapped cells with spring, staggered delays and vertical offset
        let total = otherSnapshots.count
        for (i, snap) in otherSnapshots.enumerated() {
            let delay = Double(i) / Double(max(total - 1, 1)) * 0.1
            UIView.animate(
                withDuration: 3.0,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0,
                options: [],
                animations: {
                    // Increased vertical translation to 80% of screen height
                    let maxOffset = containerView.bounds.height * 0.8
                    let yOffset: CGFloat = snap.frame.midY < self.selectedCellInitialFrame.midY
                        ? -maxOffset
                        : maxOffset
                    var t = CATransform3DIdentity
                    t = CATransform3DTranslate(t, 0, yOffset, 800)
                    snap.layer.transform = t
                },
                completion: nil
            )
        }

        // Cleanup after mask animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            for snap in otherSnapshots { snap.removeFromSuperview() }
            for cell in allCells { cell.isHidden = false }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - Collection View Controller

class CollectionViewController: UIViewController {
    
    let collectionView: UICollectionView
    let pushAnimator = PushAnimator()
    var selectedIndexPath: IndexPath?
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.sectionInset = .init(top: 16, left: 16, bottom: 16, right: 16)
        let width = UIScreen.main.bounds.width - 32
        layout.itemSize = .init(width: width, height: width / 2)
         
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        title = "Gallery"
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Collection View setup
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(RoundedCell.self, forCellWithReuseIdentifier: RoundedCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        // Apply shared perspective to collection view cells
        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 500.0
        collectionView.layer.sublayerTransform = perspective

        // Navigation Controller delegate for custom transition
        navigationController?.delegate = self
    }
}

extension CollectionViewController: UICollectionViewDataSource {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        20
    }
    
    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: RoundedCell.reuseIdentifier, for: indexPath) as! RoundedCell
        return cell
    }
}
 
extension CollectionViewController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = cv.cellForItem(at: indexPath) else { return }
        // Pass tapped cell color to detail VC
        let color = UIColor.red
        let frame = view.convert(cell.frame, from: cv)
        pushAnimator.selectedCellInitialFrame = frame
        selectedIndexPath = indexPath
        let detailVC = ZoomDetailViewController(cellColor: color)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension CollectionViewController: UINavigationControllerDelegate {
    func navigationController(
        _ nav: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return pushAnimator
        }
        return nil
    }
}

// MARK: - SwiftUI Preview

/// A helper to preview UIKit view controllers in SwiftUI canvas.
struct ZoomViewControllerPreview: UIViewControllerRepresentable {
    let viewController: UIViewController
    func makeUIViewController(context: Context) -> UIViewController { viewController }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct CustomCollectionTransition_Previews: PreviewProvider {
    static var previews: some View {
        ZoomViewControllerPreview(
            viewController: UINavigationController(rootViewController: CollectionViewController())
        )
        .edgesIgnoringSafeArea(.all)
    }
}
