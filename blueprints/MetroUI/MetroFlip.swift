//
//  MetroFlip.swift
//  blueprints
//
//  Created by decoherence on 2/23/25.
//

import SwiftUI
import UIKit

// MARK: - GridViewController

class FlipGridViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate {
    var collectionView: UICollectionView!
    let items = Array(1 ... 20)
    
    // Record which cell was tapped.
    var selectedIndexPath: IndexPath?
    var cellBaseMidX: [IndexPath: CGFloat] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        layout.minimumLineSpacing = 20
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .black
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        view.addSubview(collectionView)
    }
    
    // MARK: - UICollectionView DataSource & Delegate

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = .systemBlue
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
        let label = UILabel(frame: cell.bounds)
        label.text = "\(items[indexPath.item])"
        label.textColor = .white
        label.textAlignment = .center
        cell.contentView.addSubview(label)
            
        // Reset any previous transform
        cell.layer.transform = CATransform3DIdentity
        cell.alpha = 1
            
        // Store the base midX in the collection view’s coordinate system
        let cellFrame = cell.frame
        cellBaseMidX[indexPath] = cellFrame.midX
            
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let padding: CGFloat = 20
        let totalHorizontalPadding = padding * 2
        let interitemSpacing: CGFloat = 20
        let availableWidth = collectionView.bounds.width - totalHorizontalPadding - interitemSpacing
        let width = availableWidth / 2
        return CGSize(width: width, height: width)
    }
    
    /// Record tapped cell and push detail.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        let detailVC = DetailViewController()
        detailVC.selectedItem = items[indexPath.item]
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.delegate = self
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.backgroundColor = .clear
    }
    
    /// Provide custom animators.
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        if operation == .push, fromVC is FlipGridViewController {
            return FlipPushAnimator(gridVC: self)
        } else if operation == .pop, toVC is FlipGridViewController {
            return ReverseFlipPopAnimator(gridVC: self)
        }
        return nil
    }
}

// MARK: - DetailViewController

class FlipDetailViewController: UIViewController {
    var selectedItem: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemRed
        title = "Detail"
        
        let label = UILabel(frame: view.bounds)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.text = "Item \(selectedItem ?? 0)"
        view.addSubview(label)
        
        let image = UIImage(systemName: "person.crop.circle.fill")
        let imageView = UIImageView(image: image)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.frame = view.bounds.insetBy(dx: 20, dy: 20)
        view.addSubview(imageView)
    }
}

// MARK: - ZoomPushAnimator

/// The tapped cell's frame is used as the starting frame for the detail view.
/// Meanwhile, all other visible cells animate in descending order with a "door-swing" effect:
/// They rotate around the Y-axis (with perspective) and translate to the left offscreen.
class FlipPushAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let gridVC: FlipGridViewController

    private enum Config {
        static let animationDuration: TimeInterval = 0.4 // 250ms + max delay
    }
     
    private let perspectiveDistance: CGFloat = 2000.0
    private let rotationAngle: CGFloat = -50 * .pi / 180
     
    init(gridVC: FlipGridViewController) {
        self.gridVC = gridVC
        super.init()
    }
     
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        Config.animationDuration
    }
     
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        pushAnimation(with: transitionContext)
    }
    
    private func setup(with context: UIViewControllerContextTransitioning)
        -> (tappedCell: UICollectionViewCell, toView: UIView, toFrame: CGRect)? {
        guard let toVC = context.viewController(forKey: .to),
              let selectedIndexPath = gridVC.selectedIndexPath,
              let tappedCell = gridVC.collectionView.cellForItem(at: selectedIndexPath)
        else { return nil }
        
        let container = context.containerView
        let toFrame = context.finalFrame(for: toVC)
        toVC.view.frame = toFrame
        container.insertSubview(toVC.view, belowSubview: gridVC.view)
        
        toVC.view.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        toVC.view.layer.position.x = container.bounds.minX
        var initialTransform = CATransform3DIdentity
        initialTransform.m34 = -1.0 / perspectiveDistance
        initialTransform = CATransform3DRotate(initialTransform, .pi / 2, 0, 1, 0)
        toVC.view.layer.transform = initialTransform
        
        return (tappedCell, toVC.view, toFrame)
    }
    
    private func pushAnimation(with context: UIViewControllerContextTransitioning) {
        guard let (tappedCell, toView, toFrame) = setup(with: context) else {
            context.completeTransition(false)
            return
        }
        
        let container = context.containerView
        gridVC.collectionView.backgroundColor = .clear
        
        let nonTappedCells = gridVC.collectionView.visibleCells.filter { $0 != tappedCell }
        let duration = 0.25 // WP7’s 250ms per tile
        
        let xFactor: CGFloat = -0.00047143
        let yFactor: CGFloat = 0.001714
        let randomFactor: CGFloat = 0.0714
        let random = Random()
          
        for cell in nonTappedCells {
            let positionInContainer = cell.convert(CGPoint.zero, to: container)
            let x = positionInContainer.x
            let y = container.bounds.height - positionInContainer.y
            let delayFactor = y * yFactor + x * xFactor + CGFloat(random.nextInt(in: -1 ... 1)) * randomFactor
            let delay = duration * Double(delayFactor)
            let finalDelay = max(0, delay)
            
            animateDoorCell(cell, delay: finalDelay, container: container)
        }
        
        let maxNonTappedDelay = duration * Double(container.bounds.height * yFactor + randomFactor)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + maxNonTappedDelay) {
            self.animateDoorCell(tappedCell, delay: 0, container: container)
            UIView.animate(withDuration: duration,
                           delay: 0.5,
                           options: [.curveEaseInOut],
                           animations: {
                               toView.layer.transform = CATransform3DIdentity
                           },
                           completion: { _ in
                               self.gridVC.view.removeFromSuperview()
                               context.completeTransition(!context.transitionWasCancelled)
                           })
        }
    }
    
    private func animateDoorCell(_ cell: UIView, delay: TimeInterval, container: UIView) {
        let cellLayer = cell.layer
        let containerMidY = container.bounds.height / 2
        let positionInContainer = cell.convert(CGPoint.zero, to: container)
        let cellTopInContainer = positionInContainer.y
        let localOffsetY = cellTopInContainer - containerMidY
        
        let containerLeftEdgeInCell = cell.convert(CGPoint.zero, from: container)
        let anchorX = containerLeftEdgeInCell.x / cell.bounds.width
        let oldAnchorPoint = cellLayer.anchorPoint
        let oldPosition = cellLayer.position
        
        cellLayer.anchorPoint = CGPoint(x: anchorX, y: 0.5)
        let positionShiftX = (anchorX - oldAnchorPoint.x) * cell.bounds.width
        cellLayer.position = CGPoint(x: oldPosition.x + positionShiftX, y: oldPosition.y)
        
        var initialTransform = CATransform3DIdentity
        initialTransform.m34 = -1.0 / perspectiveDistance
        initialTransform = CATransform3DTranslate(initialTransform, 0, localOffsetY, 0)
        
        var finalTransform = initialTransform
        finalTransform = CATransform3DRotate(finalTransform, rotationAngle, 0, 1, 0)
        
        cellLayer.transform = initialTransform
        let newPositionInContainer = cell.convert(CGPoint.zero, to: container)
        let yOffsetAfterTransform = positionInContainer.y - newPositionInContainer.y
        cellLayer.position.y = oldPosition.y + yOffsetAfterTransform
        
        // Rotation animation
        let rotationStart = CACurrentMediaTime() + delay
        let rotationAnim = CABasicAnimation(keyPath: "transform")
        rotationAnim.fromValue = initialTransform
        rotationAnim.toValue = finalTransform
        rotationAnim.duration = 0.25
        rotationAnim.timingFunction = CAMediaTimingFunction(controlPoints: 0.95, 0.0, 1.0, 1.0)
        rotationAnim.beginTime = rotationStart
        rotationAnim.fillMode = .forwards
        rotationAnim.isRemovedOnCompletion = false
        
        // Opacity animation - instant at flip completion
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 1.0
        opacityAnim.toValue = 0.0
        opacityAnim.duration = 0.01 // 10ms, super abrupt
        opacityAnim.beginTime = rotationStart + 0.255 // Start exactly at rotation end (250ms)
        opacityAnim.fillMode = .forwards
        opacityAnim.isRemovedOnCompletion = false
        
        cellLayer.add(rotationAnim, forKey: "transformAnimation")
        cellLayer.add(opacityAnim, forKey: "opacityAnimation")
        
        print("Rotation start: \(rotationStart), end: \(rotationStart + 0.25), Opacity start: \(opacityAnim.beginTime), end: \(opacityAnim.beginTime + 0.01)")
    }
}

class Random {
    private let generator: UInt64
    
    init() {
        generator = UInt64.random(in: 0 ... UInt64.max)
    }
    
    func nextInt(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        let randomValue = generator % span
        return range.lowerBound + Int(randomValue)
    }
}

// MARK: - ReverseZoomPopAnimator

/// The detail view zooms back into the tapped cell while the other cells animate back in by reversing the door-swing effect in descending order.

class ReverseFlipPopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let gridVC: FlipGridViewController

    private enum Config {
        static let animationDuration: TimeInterval = 1.0
        static let placeholderColor = UIColor.red
        static let maskCornerRadius: CGFloat = 10.0
        static let overlayOpacity: Float = 0.5
    }
    
    private let perspectiveDistance: CGFloat = 500.0
    private let rotationAngle: CGFloat = .pi / 2
    private let mass: CGFloat = 1.0
    private let stiffness: CGFloat = 200.0
    private let damping: CGFloat = 25.0
    private let initialVelocity: CGFloat = 0.0

    init(gridVC: FlipGridViewController) {
        self.gridVC = gridVC
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Config.animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let (fromView, fromFrame, toView, toFrame) = setup(with: transitionContext) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let container = transitionContext.containerView
        
        // Set up backdrop and placeholder
        let backdrop = UIView(frame: toView.frame)
        backdrop.backgroundColor = .black
        backdrop.layer.opacity = Config.overlayOpacity
        toView.addSubview(backdrop)
        
        let placeholder = UIView(frame: toFrame)
        placeholder.backgroundColor = Config.placeholderColor
        toView.addSubview(placeholder)
        
        // Mask for shrinking detail view
        let mask = UIView(frame: fromView.frame)
        mask.backgroundColor = .black
        mask.layer.cornerCurve = .continuous
        mask.layer.cornerRadius = Config.maskCornerRadius
        fromView.mask = mask
        
        // Calculate transform to shrink detail view back to cell
        let transform = CGAffineTransform.transform(
            parent: fromView.frame,
            suchThatChild: fromFrame,
            aspectFills: toFrame
        )
        let maskFrame = toFrame.aspectFit(to: fromFrame)
        
        // Animate non-tapped cells
        let otherCells = gridVC.collectionView.visibleCells.filter {
            guard let ip = gridVC.collectionView.indexPath(for: $0) else { return false }
            return ip != gridVC.selectedIndexPath
        }
        let sortedCells = otherCells.sorted { cellA, cellB in
            guard let ipA = gridVC.collectionView.indexPath(for: cellA),
                  let ipB = gridVC.collectionView.indexPath(for: cellB) else { return false }
            return ipA.item < ipB.item // Reverse order for pop (left-to-right)
        }
        
        // Pre-set cells to open state
        for cell in sortedCells {
            let containerLeftEdgeInCell = cell.convert(CGPoint.zero, from: container)
            let anchorX = containerLeftEdgeInCell.x / cell.bounds.width
            let oldAnchorPoint = cell.layer.anchorPoint
            cell.layer.anchorPoint = CGPoint(x: anchorX, y: 0.5)
            let positionShiftX = (anchorX - oldAnchorPoint.x) * cell.bounds.width
            cell.layer.position.x += positionShiftX
            var openTransform = CATransform3DIdentity
            openTransform.m34 = -1.0 / perspectiveDistance
            openTransform = CATransform3DRotate(openTransform, rotationAngle, 0, 1, 0)
            cell.layer.transform = openTransform
        }
        
        // Animate cells back to flat
        for (i, cell) in sortedCells.enumerated() {
            let delay = 0.06 * Double(i)
            animateDoorCell(cell, delay: delay, container: container)
        }
        
        let totalDelay = 0.06 * Double(sortedCells.count)
        let animator = UIViewPropertyAnimator(duration: 0.1, dampingRatio: 0.8) {
            fromView.transform = transform
            mask.frame = maskFrame
            mask.layer.cornerRadius = 0
            backdrop.layer.opacity = 0
        }
        animator.addCompletion { _ in
            fromView.mask = nil
            backdrop.removeFromSuperview()
            placeholder.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        animator.startAnimation(afterDelay: 0)
    }
    
    private func setup(with context: UIViewControllerContextTransitioning)
        -> (fromView: UIView, fromFrame: CGRect, toView: UIView, toFrame: CGRect)?
    {
        guard let fromVC = context.viewController(forKey: .from),
              let toVC = context.viewController(forKey: .to),
              let selectedIndexPath = gridVC.selectedIndexPath,
              let tappedCell = gridVC.collectionView.cellForItem(at: selectedIndexPath)
        else { return nil }
        
        let container = context.containerView
        let cellFrame = tappedCell.convert(tappedCell.bounds, to: container)
        let fromFrame = fromVC.view.frame
        let toFrame = cellFrame
        
        container.insertSubview(toVC.view, belowSubview: fromVC.view)
        return (fromView: fromVC.view, fromFrame: fromFrame, toView: toVC.view, toFrame: toFrame)
    }
    
    private func animateDoorCell(_ cell: UIView, delay: TimeInterval, container: UIView) {
        // Anchor point already set; just animate rotation
        let rotationAnim = CASpringAnimation(keyPath: "transform.rotation.y")
        rotationAnim.fromValue = rotationAngle
        rotationAnim.toValue = 0
        rotationAnim.mass = mass
        rotationAnim.stiffness = stiffness
        rotationAnim.damping = damping
        rotationAnim.initialVelocity = initialVelocity
        rotationAnim.beginTime = CACurrentMediaTime() + delay
        rotationAnim.duration = rotationAnim.settlingDuration
        rotationAnim.fillMode = .forwards
        rotationAnim.isRemovedOnCompletion = false
        
        cell.layer.add(rotationAnim, forKey: "springRotation")
    }
}

// MARK: - SwiftUI Preview Wrapper

struct FlipViewControllerPreview: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let gridVC = FlipGridViewController()
        return UINavigationController(rootViewController: gridVC)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

struct FlipViewControllerPreview_Previews: PreviewProvider {
    static var previews: some View {
        FlipViewControllerPreview()
            .ignoresSafeArea()
    }
}
