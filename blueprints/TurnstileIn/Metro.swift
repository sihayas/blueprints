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
        static let placeholderColor = UIColor.green
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
                  let ipB = gridVC.collectionView.indexPath(for: cellB)
            else { return false }
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
                       delay: 0.6,
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
        rotationAnim.fillMode = .forwards
        rotationAnim.isRemovedOnCompletion = false
        
        let translationXAnim = CASpringAnimation(keyPath: "transform.translation.x")
        translationXAnim.fromValue = 0
        translationXAnim.toValue = -mirroredX
        translationXAnim.mass = mass
        translationXAnim.stiffness = stiffness
        translationXAnim.damping = damping
        translationXAnim.initialVelocity = initialVelocity
        translationXAnim.beginTime = CACurrentMediaTime() + delay
        translationXAnim.duration = springDuration
        translationXAnim.fillMode = .forwards
        translationXAnim.isRemovedOnCompletion = false
        
        let translationZAnim = CASpringAnimation(keyPath: "transform.translation.z")
        translationZAnim.fromValue = 0
        translationZAnim.toValue = zTranslation
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
        
        // Ensure the cell remains in its final animated state until we update its model layer.
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + springDuration) {
            var finalTransform = CATransform3DIdentity
            finalTransform.m34 = 1.0 / self.perspectiveDistance
            cell.layer.transform = finalTransform
        }
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

// MARK: - ReverseZoomPopAnimator

/// The detail view zooms back into the tapped cell while the other cells animate back in by reversing the door-swing effect in descending order.

class ReverseZoomPopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let gridVC: GridViewController

    // MARK: - Configurations
    private struct Config {
        static let placeholderColor = UIColor.red
        static let maskCornerRadius: CGFloat = 10.0
        static let overlayOpacity: Float = 0.5
        static let animationDuration: TimeInterval = 0.4
        static let springDamping: CGFloat = 2.0
        static let springVelocity: CGFloat = 0.4
    }
    
    // Parameters for door cell (flip) animation
    private let perspectiveDistance: CGFloat = 500.0
    private let zTranslation: CGFloat = 1000.0
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
        return Config.animationDuration
    }
    
    // Setup: fromView is the detail (popped) view, toView is the grid.
    private func setup(with context: UIViewControllerContextTransitioning)
      -> (fromView: UIView, fromFrame: CGRect, toView: UIView, toFrame: CGRect)? {
        guard let fromVC = context.viewController(forKey: .from),
              let toVC = context.viewController(forKey: .to),
              let selectedIndexPath = gridVC.selectedIndexPath,
              let tappedCell = gridVC.collectionView.cellForItem(at: selectedIndexPath)
        else { return nil }
        
        let container = context.containerView
        let cellFrame = tappedCell.convert(tappedCell.bounds, to: container)
        let fromFrame = fromVC.view.frame
        let toFrame = cellFrame
        
        // Insert grid view beneath the detail view.
        container.insertSubview(toVC.view, belowSubview: fromVC.view)
        
        return (fromView: fromVC.view, fromFrame: fromFrame, toView: toVC.view, toFrame: toFrame)
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let (fromView, fromFrame, toView, toFrame) = setup(with: transitionContext) else {
            transitionContext.completeTransition(false)
            return
        }
        let container = transitionContext.containerView
        
        // Calculate transform so the detail view shrinks back into the tapped cell.
        let transform = CGAffineTransform.transform(
            parent: fromView.frame,
            suchThatChild: fromFrame,
            aspectFills: toFrame
        )
        
        // Create a mask on the detail view.
        let mask = UIView(frame: fromView.frame).then {
            $0.layer.cornerCurve = .continuous
            $0.backgroundColor = .black
            $0.layer.cornerRadius = Config.maskCornerRadius
        }
        fromView.mask = mask
        
        // Add a dark backdrop to the grid view.
        let backdrop = UIView().then {
            $0.backgroundColor = .black
            $0.layer.opacity = Config.overlayOpacity
            $0.frame = toView.frame
        }
        toView.addSubview(backdrop)
        
        // Add a placeholder over the tapped cell.
        let placeholder = UIView().then {
            $0.backgroundColor = Config.placeholderColor
            $0.frame = toFrame
        }
        toView.addSubview(placeholder)
        
        // Final mask frame.
        let maskFrame = toFrame.aspectFit(to: fromFrame)
        
        // Animate door (flip) for all grid cells except the tapped cell.
        let otherCells = gridVC.collectionView.visibleCells.filter {
            guard let ip = gridVC.collectionView.indexPath(for: $0) else { return false }
            return ip != gridVC.selectedIndexPath
        }
        // Pre-set off–screen state.
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
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: Config.springDamping,
                       initialSpringVelocity: Config.springVelocity,
                       options: [],
                       animations: {
            fromView.transform = transform
            mask.frame = maskFrame
            mask.layer.cornerRadius = 0
            backdrop.layer.opacity = 0
        }, completion: { _ in
            fromView.mask = nil
            backdrop.removeFromSuperview()
            placeholder.removeFromSuperview()
            let cancelled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!cancelled)
        })
    }
    
    // MARK: - Door Cell (Flip) Animations
    
    private func mirroredXTranslation(for cell: UIView, in container: UIView) -> CGFloat {
        guard let indexPath = gridVC.collectionView.indexPath(for: cell as? UICollectionViewCell ?? UICollectionViewCell()),
              let baseMidX = gridVC.cellBaseMidX[indexPath]
        else { return 0 }
        
        let cellCenterX = gridVC.collectionView.convert(CGPoint(x: baseMidX, y: 0), to: container).x
        let scaleFactor = (perspectiveDistance + zTranslation) / perspectiveDistance
        return cellCenterX * scaleFactor
    }
    
    private func doorOpenTransform(for cell: UIView, in container: UIView) -> CATransform3D {
        var transform = CATransform3DIdentity
        cell.setAnchorPoint(CGPoint(x: 0, y: 0.5))
        transform.m34 = 1.0 / perspectiveDistance
        
        let adjustedX = mirroredXTranslation(for: cell, in: container)
        transform = CATransform3DTranslate(transform, -adjustedX, 0, zTranslation)
        transform = CATransform3DRotate(transform, rotationAngle, 0, 1, 0)
        return transform
    }
    
    private func animateDoorCell(_ cell: UIView, delay: TimeInterval, container: UIView) {
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
