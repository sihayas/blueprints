import SwiftUI
import UIKit

// MARK: - GridViewController

class GridViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate {
    var collectionView: UICollectionView!
    let items = Array(1 ... 20)
    
    // Record which cell was tapped.
    var selectedIndexPath: IndexPath?
    var cellBaseMidX: [IndexPath: CGFloat] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Grid"
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        view.addSubview(collectionView)
        
        print("CollectionView: bounds.width = \(collectionView.bounds.width), frame.origin = \(collectionView.frame.origin)")
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
    }
    
    /// Provide custom animators.
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        if operation == .push, fromVC is GridViewController {
            return ZoomPushAnimator(gridVC: self)
        } else if operation == .pop, toVC is GridViewController {
            return ReverseZoomPopAnimator(gridVC: self)
        }
        return nil
    }
}

// MARK: - DetailViewController

class DetailViewController: UIViewController {
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
class ZoomPushAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let gridVC: GridViewController

    // MARK: - Configurations
    private struct Config {
        static let placeholderColor = UIColor.white
        static let maskCornerRadius: CGFloat = 10.0
        static let overlayOpacity: Float = 0.5
        static let animationDuration: TimeInterval = 0.4
        static let springDamping: CGFloat = 2.0
        static let springVelocity: CGFloat = 0.4
    }
    
    // Parameters for door cell animation
    private let perspectiveDistance: CGFloat = 500.0
    private let zTranslation: CGFloat = -150.0
    private let rotationAngle: CGFloat = CGFloat.pi / 2
    private let mass: CGFloat = 1.0
    private let stiffness: CGFloat = 200.0
    private let damping: CGFloat = 25.0
    private let initialVelocity: CGFloat = 0.0
    
    init(gridVC: GridViewController) {
        self.gridVC = gridVC
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Config.animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        pushAnimation(with: transitionContext)
    }
    
    private func setup(with context: UIViewControllerContextTransitioning)
      -> (fromView: UIView, fromFrame: CGRect, toView: UIView, toFrame: CGRect)? {
        
        guard let toVC = context.viewController(forKey: .to),
              let selectedIndexPath = gridVC.selectedIndexPath,
              let tappedCell = gridVC.collectionView.cellForItem(at: selectedIndexPath)
        else {
            return nil
        }
        
        let container = context.containerView
        let fromFrame = tappedCell.convert(tappedCell.bounds, to: container)
        let toFrame = context.finalFrame(for: toVC)
        
        // Add destination view to container.
        toVC.view.frame = toFrame
        container.addSubview(toVC.view)
        
        return (fromView: tappedCell, fromFrame: fromFrame, toView: toVC.view, toFrame: toFrame)
    }
    
    private func pushAnimation(with context: UIViewControllerContextTransitioning) {
        guard let (fromView, fromFrame, toView, toFrame) = setup(with: context) else {
            context.completeTransition(false)
            return
        }
        
        // Start door-cell animations for other cells
        let container = context.containerView
        let otherCells = gridVC.collectionView.visibleCells.filter { $0 != fromView }
        let sortedCells = otherCells.sorted { cellA, cellB in
            guard let ipA = gridVC.collectionView.indexPath(for: cellA),
                  let ipB = gridVC.collectionView.indexPath(for: cellB) else {
                return false
            }
            return ipA.item > ipB.item
        }
        for (i, cell) in sortedCells.enumerated() {
            let delay = 0.1 * Double(i)
            animateDoorCell(cell, delay: delay, container: container)
        }
        
        // Calculate the transform so the destination view appears to expand from the tapped cell.
        let transform = CGAffineTransform.transform(
            parent: toView.frame,
            suchThatChild: toFrame,
            aspectFills: fromFrame
        )
        toView.transform = transform
        
        // Create a mask that will expand during the animation.
        let maskFrame = fromFrame.aspectFit(to: toFrame)
        let mask = UIView(frame: maskFrame).then {
            $0.layer.cornerCurve = .continuous
            $0.backgroundColor = .black
        }
        toView.mask = mask
        
        // Add a placeholder over the tapped cell.
        let placeholder = UIView().then {
            $0.backgroundColor = Config.placeholderColor
            $0.frame = fromFrame
        }
        fromView.addSubview(placeholder)
        
        // Add a dark backdrop to the tapped cell.
        let backdrop = UIView().then {
            $0.backgroundColor = .black
            $0.layer.opacity = 0
            $0.frame = fromView.bounds
        }
        fromView.addSubview(backdrop)
        
        // Animate to reveal the destination view while expanding the mask.
        UIView.animate(withDuration: transitionDuration(using: context),
                       delay: 0,
                       usingSpringWithDamping: Config.springDamping,
                       initialSpringVelocity: Config.springVelocity,
                       options: [],
                       animations: {
            toView.transform = .identity
            mask.frame = toView.bounds
            mask.layer.cornerRadius = Config.maskCornerRadius
            backdrop.layer.opacity = Config.overlayOpacity
        }, completion: { _ in
            toView.mask = nil
            backdrop.removeFromSuperview()
            placeholder.removeFromSuperview()
            context.completeTransition(true)
        })
    }
    
    // MARK: - Door Cell Animation (Flipping Other Cells)
    private func animateDoorCell(_ cell: UIView, delay: TimeInterval, container: UIView) {
        let springDuration = transitionDuration(using: nil)
        let mirroredX = mirroredXTranslation(for: cell, in: container)
        
        cell.setAnchorPoint(CGPoint(x: 0, y: 0.5))
        var initialTransform = CATransform3DIdentity
        initialTransform.m34 = 1.0 / perspectiveDistance
        cell.layer.transform = initialTransform
        
        let rotationAnim = CASpringAnimation(keyPath: "transform.rotation.y")
        rotationAnim.fromValue = 0
        rotationAnim.toValue = rotationAngle
        rotationAnim.mass = mass
        rotationAnim.stiffness = stiffness
        rotationAnim.damping = damping
        rotationAnim.initialVelocity = initialVelocity
        rotationAnim.beginTime = CACurrentMediaTime() + delay
        rotationAnim.duration = springDuration
        
        let translationXAnim = CASpringAnimation(keyPath: "transform.translation.x")
        translationXAnim.fromValue = 0
        translationXAnim.toValue = -mirroredX
        translationXAnim.mass = mass
        translationXAnim.stiffness = stiffness
        translationXAnim.damping = damping
        translationXAnim.initialVelocity = initialVelocity
        translationXAnim.beginTime = CACurrentMediaTime() + delay
        translationXAnim.duration = springDuration
        
        let translationZAnim = CASpringAnimation(keyPath: "transform.translation.z")
        translationZAnim.fromValue = 0
        translationZAnim.toValue = zTranslation
        translationZAnim.mass = mass
        translationZAnim.stiffness = stiffness
        translationZAnim.damping = damping
        translationZAnim.initialVelocity = initialVelocity
        translationZAnim.beginTime = CACurrentMediaTime() + delay
        translationZAnim.duration = springDuration
        
        cell.layer.add(rotationAnim, forKey: "springRotation")
        cell.layer.add(translationXAnim, forKey: "springTranslationX")
        cell.layer.add(translationZAnim, forKey: "springTranslationZ")
    }
    
    private func mirroredXTranslation(for cell: UIView, in container: UIView) -> CGFloat {
        guard let cellIndex = gridVC.collectionView.indexPath(for: cell as? UICollectionViewCell ?? UICollectionViewCell()),
              let baseMidX = gridVC.cellBaseMidX[cellIndex]
        else {
            return 0
        }
        let cellCenterX = gridVC.collectionView.convert(CGPoint(x: baseMidX, y: 0), to: container).x
        let scaleFactor = (perspectiveDistance + zTranslation) / perspectiveDistance
        return cellCenterX * scaleFactor
    }
}

// Utility extension to allow immediate property configuration.
protocol Then {}
extension Then where Self: AnyObject {
    func then(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}
extension NSObject: Then {}

extension CGRect {
    /// Main  `aspectFit` method that decides whether to fit by width or height.
    /// Used by the mask view in `SharedTransitionAnimationController`.
    ///
    func aspectFit(to frame: CGRect) -> CGRect {
        let ratio = width / height
        let frameRatio = frame.width / frame.height
        
        // If target frame is narrower than original, fit to width,
        // else if target frame is wider than original, fit to height
        if frameRatio < ratio {
            return aspectFitWidth(to: frame)
        } else {
            return aspectFitHeight(to: frame)
        }
    }

    // Fits the rect to the target frame's width while maintaining aspect ratio,
    // and centers the result vertically in the target frame
    func aspectFitWidth(to frame: CGRect) -> CGRect {
        let ratio = width / height
        let height = frame.width * ratio
        let offsetY = (frame.height - height) / 2 // Center vertically
        let origin = CGPoint(x: frame.origin.x, y: frame.origin.y + offsetY)
        let size = CGSize(width: frame.width, height: height)
        return CGRect(origin: origin, size: size)
    }

    // Fits the rect to the target frame's height while maintaining aspect ratio,
    // and cnters the result horizontally in the target frame
    func aspectFitHeight(to frame: CGRect) -> CGRect {
        let ratio = height / width
        let width = frame.height * ratio
        let offsetX = (frame.width - width) / 2 // Center horizontally
        let origin = CGPoint(x: frame.origin.x + offsetX, y: frame.origin.y)
        let size = CGSize(width: width, height: frame.height)
        return CGRect(origin: origin, size: size)
    }
}

extension CGAffineTransform {
    /// Basic transform that combines scaling and translation
    ///
    static func transform(from frameA: CGRect, to frameB: CGRect) -> Self {
        let scale = scale(from: frameA, to: frameB)
        let translation = translate(from: frameA, to: frameB)
        return scale.concatenating(translation)
    }

    /// Calculates the translation needed to move from center of `frameA` to center of `frameB`
    ///
    static func translate(from frameA: CGRect, to frameB: CGRect) -> Self {
        let centerA = CGPoint(x: frameA.midX, y: frameA.midY)
        let centerB = CGPoint(x: frameB.midX, y: frameB.midY)
        return CGAffineTransform(
            translationX: centerB.x - centerA.x,
            y: centerB.y - centerA.y
        )
    }

    /// Calculates the scale factor needed to make `frameA` match `frameB`'s size
    ///
    static func scale(from frameA: CGRect, to frameB: CGRect) -> Self {
        let scaleX = frameB.width / frameA.width
        let scaleY = frameB.height / frameA.height
        return CGAffineTransform(scaleX: scaleX, y: scaleY)
    }

    /// A function that calculates the transformations required based on the three
    /// participating rects in a `SharedTransition`.
    ///
    /// - `parent`: The container view's frame
    /// - `child`: The view within the parent that we want to transform
    /// - `targetRect`: The target frame we want the child to match exactly
    ///
    /// For example, given the following two views that we want to transition between:
    ///
    /*
        +-------+    +-------------+
        |       |    |      B      |
        |   A   |    +-------------+
        |       |    |             |
        +-------+    |             |
                     |      C      |
                     |             |
                     |             |
                     +-------------+
                     |      B      |
                     +-------------+
    */
    ///
    /// The `parent` is B, the `child` is C (the rect we aim to overlap with another rect
    /// post-transformation), and the `rect` is A (the rect whose geometry we want the child to match
    /// with exactly).
    ///
    /// However, this function is not the one we shoud use, as the aspect ratio alters as A goes to C and back.
    /// This results in a distorted view since they are stretched and reshaped. The other
    /// `transform(parent:suchThatChild:aspectFills)` function is better suited for our needs.
    ///
    static func transform(parent: CGRect,
                          suchThatChild child: CGRect,
                          matches targetRect: CGRect) -> Self
    {
        // Calculate scale factors by comparing child rectangle's (C) dimensions
        // with the target rectangle (A)
        let scaleX = targetRect.width / child.width
        let scaleY = targetRect.height / child.height

        // Determine the origin of the animation by aligning the
        // centers of the rects.
        //
        // First, we match the center of the parent rect to the target rect.
        //
        // Second, we adjust the offset so that the child rect's center is aligned
        // with the target (calculated as the diff between the centers of the
        // parent and child rect in their scaled form).
        //
        // Without this, the view will always transition from the center of
        // the screen, instead of from where the transition should begin (i.e.
        // from a cell in a collection view).
        let offsetX = targetRect.midX - parent.midX
        let offsetY = targetRect.midY - parent.midY
        let centerOffsetX = (parent.midX - child.midX) * scaleX
        let centerOffsetY = (parent.midY - child.midY) * scaleY
        let translateX = offsetX + centerOffsetX
        let translateY = offsetY + centerOffsetY

        // Finally, create and combine the transformations into one
        // CGAffineTransform, ready to be applied to our views.
        let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        let translateTransform = CGAffineTransform(translationX: translateX,
                                                   y: translateY)
        
        return scaleTransform.concatenating(translateTransform)
    }

    /// A similar transform function as the one above, but employing `aspectFill` to circumvent
    /// distortion of views during transition. With this, the child rect retains its aspect ratio while being transformed
    /// to fit perfectly within the target rect.
    ///
    /// However, this introduces another problem: parts of the child rect now extend beyond the bounds of the target rect
    /// and this is especially visible during the last few frames of the animation. We will need to apply a mask during the
    /// transition to hide this. Please see `CGRect+Extensions.swift` for the relevant utility functions.
    ///
    static func transform(parent: CGRect,
                          suchThatChild child: CGRect,
                          aspectFills targetRect: CGRect) -> Self
    {
        // Calculate aspect ratio of both child and target rect frames
        let childRatio = child.width / child.height
        let rectRatio = targetRect.width / targetRect.height

        let scaleX = targetRect.width / child.width
        let scaleY = targetRect.height / child.height

        // Determine the scaling dimension based on a comparison of the two ratios,
        // ensuring we maintain the original aspect while fitting the rectangle.
        let scaleFactor = rectRatio < childRatio ? scaleY : scaleX

        let offsetX = targetRect.midX - parent.midX
        let offsetY = targetRect.midY - parent.midY
        let centerOffsetX = (parent.midX - child.midX) * scaleFactor
        let centerOffsetY = (parent.midY - child.midY) * scaleFactor

        let translateX = offsetX + centerOffsetX
        let translateY = offsetY + centerOffsetY

        let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let translateTransform = CGAffineTransform(translationX: translateX,
                                                   y: translateY)

        return scaleTransform.concatenating(translateTransform)
    }
    
    /// Transform a frame into another frame. Assumes they're the same aspect ratio.
    static func transform(originalFrame: CGRect,
                          toTargetFrame targetFrame: CGRect) -> Self
    {
        // Width or height doesn't matter if they're the same aspect ratio
        let scaleFactor = targetFrame.width / originalFrame.width
        
        let offsetX = targetFrame.midX - originalFrame.midX
        let offsetY = targetFrame.midY - originalFrame.midY
        
        let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let translateTransform = CGAffineTransform(translationX: offsetX,
                                                   y: offsetY)
        
        return scaleTransform.concatenating(translateTransform)
    }
}

// MARK: - ReverseZoomPopAnimator

/// The detail view zooms back into the tapped cell while the other cells animate back in
/// by reversing the door-swing effect in descending order.
class ReverseZoomPopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let gridVC: GridViewController
    
    private let perspectiveDistance: CGFloat = 500.0
    private let zTranslation: CGFloat = 850.0
    private let rotationAngle: CGFloat = -CGFloat.pi
    private let mass: CGFloat = 1.0
    private let stiffness: CGFloat = 200.0
    private let damping: CGFloat = 25.0
    private let initialVelocity: CGFloat = 0.0

    init(gridVC: GridViewController) {
        self.gridVC = gridVC
        super.init()
    }
 
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    /// Helper: Determine the cell's offset position as if the screen were mirorred horizontally, considering perspective and zTranslation.
    private func mirroredXTranslation(for cell: UIView, in container: UIView) -> CGFloat {
        guard let indexPath = gridVC.collectionView.indexPath(for: cell as? UICollectionViewCell ?? UICollectionViewCell()),
              let baseMidX = gridVC.cellBaseMidX[indexPath] else {
            return 0
        }
        let cellCenterX = gridVC.collectionView.convert(CGPoint(x: baseMidX, y: 0), to: container).x
        
        /// Based on the cell's resting position in the grid, calculate how much you need to translate it to the left to technically be mirrorred horizontally.
        let scaleFactor = (perspectiveDistance + zTranslation) / perspectiveDistance
        return cellCenterX * scaleFactor
    }
    
    /// Sets the cell's initial off–screen state.
    func doorOpenTransform(for cell: UIView, in container: UIView) -> CATransform3D {
        var transform = CATransform3DIdentity
        cell.setAnchorPoint(CGPoint(x: 0, y: 0.5))
        transform.m34 = 1.0 / perspectiveDistance
        
        let adjustedX = mirroredXTranslation(for: cell, in: container)
        
        transform = CATransform3DTranslate(transform, -adjustedX, 0, zTranslation)
        transform = CATransform3DRotate(transform, rotationAngle, 0, 1, 0)
        return transform
    }
    
    /// Animates the cell from the off–screen state (set by doorOpenTransform) back to its original position.
    func animateDoorCell(_ cell: UIView, delay: TimeInterval, container: UIView) {
        let springDuration = transitionDuration(using: nil)
        
        let mirroredX = mirroredXTranslation(for: cell, in: container)
        
        let rotationAnim = CASpringAnimation(keyPath: "transform.rotation.y")
        rotationAnim.fromValue = rotationAngle
        rotationAnim.toValue = 0
        rotationAnim.mass = mass
        rotationAnim.stiffness = stiffness
        rotationAnim.damping = damping
        rotationAnim.initialVelocity = initialVelocity
        rotationAnim.beginTime = CACurrentMediaTime() + delay
        rotationAnim.duration = springDuration
        rotationAnim.fillMode = .forwards
        rotationAnim.isRemovedOnCompletion = false
        
        let translationXAnim = CASpringAnimation(keyPath: "transform.translation.x")
        translationXAnim.fromValue = -mirroredX
        translationXAnim.toValue = 0
        translationXAnim.mass = mass
        translationXAnim.stiffness = stiffness
        translationXAnim.damping = damping
        translationXAnim.initialVelocity = initialVelocity
        translationXAnim.beginTime = CACurrentMediaTime() + delay
        translationXAnim.duration = springDuration
        translationXAnim.fillMode = .forwards
        translationXAnim.isRemovedOnCompletion = false
        
        let translationZAnim = CASpringAnimation(keyPath: "transform.translation.z")
        translationZAnim.fromValue = zTranslation
        translationZAnim.toValue = 0
        translationZAnim.mass = mass
        translationZAnim.stiffness = stiffness
        translationZAnim.damping = damping
        translationZAnim.initialVelocity = initialVelocity
        translationZAnim.beginTime = CACurrentMediaTime() + delay
        translationZAnim.duration = springDuration
        translationZAnim.fillMode = .forwards
        translationZAnim.isRemovedOnCompletion = false
        
        cell.layer.add(rotationAnim, forKey: "springRotation")
        cell.layer.add(translationXAnim, forKey: "springTranslationX")
        cell.layer.add(translationZAnim, forKey: "springTranslationZ")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + springDuration) {
            var finalTransform = CATransform3DIdentity
            finalTransform.m34 = 1.0 / self.perspectiveDistance
            cell.layer.transform = finalTransform
        }
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let selectedIndexPath = gridVC.selectedIndexPath,
              let tappedCell = gridVC.collectionView.cellForItem(at: selectedIndexPath)
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        let container = transitionContext.containerView
        let cellFrame = tappedCell.convert(tappedCell.bounds, to: container)
        
        if let toVC = transitionContext.viewController(forKey: .to) {
            container.insertSubview(toVC.view, belowSubview: fromVC.view)
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromVC.view.frame = cellFrame
            fromVC.view.alpha = 0
        })
        
        let otherCells = gridVC.collectionView.visibleCells.filter { $0 != tappedCell }
        for cell in otherCells {
            cell.layer.transform = doorOpenTransform(for: cell, in: container)
        }
        
        let sortedCells = otherCells.sorted { cellA, cellB in
            guard let ipA = gridVC.collectionView.indexPath(for: cellA),
                  let ipB = gridVC.collectionView.indexPath(for: cellB)
            else { return false }
            return ipA.item > ipB.item
        }
        
        for (i, cell) in sortedCells.enumerated() {
            let delay = 0.1 * Double(i)
            animateDoorCell(cell, delay: delay, container: container)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration(using: transitionContext)) {
            fromVC.view.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - SwiftUI Preview Wrapper

struct ViewControllerPreview: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let gridVC = GridViewController()
        return UINavigationController(rootViewController: gridVC)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

struct ViewControllerPreview_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerPreview()
            .ignoresSafeArea()
    }
}

extension UIView {
    /// Safely set a new anchor point without shifting the view.
    func setAnchorPoint(_ point: CGPoint) {
        var newPoint = CGPoint(x: bounds.width * point.x, y: bounds.height * point.y)
        var oldPoint = CGPoint(x: bounds.width * layer.anchorPoint.x, y: bounds.height * layer.anchorPoint.y)
        
        newPoint = newPoint.applying(transform)
        oldPoint = oldPoint.applying(transform)
        
        var position = layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        layer.position = position
        layer.anchorPoint = point
    }
}
