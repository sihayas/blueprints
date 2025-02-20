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
    
    // Record tapped cell and push detail.
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
    
    // Provide custom animators.
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
    }
}

// MARK: - ZoomPushAnimator

/// The tapped cell's frame is used as the starting frame for the detail view.
/// Meanwhile, all other visible cells animate in descending order with a "door-swing" effect:
/// They rotate around the Y-axis (with perspective) and translate to the left offscreen.
class ZoomPushAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let gridVC: GridViewController
    
    init(gridVC: GridViewController) {
        self.gridVC = gridVC
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
     
    // Helper: Returns the door-open transform for a given cell.
    func doorOpenTransform(for cell: UIView) -> CATransform3D {
        var transform = CATransform3DIdentity
        transform.m34 = 1.0 / 750.0 // Add perspective.
        // Translate left and also pull the cell toward the viewer along the z-axis.
        transform = CATransform3DTranslate(transform, -cell.bounds.width * 2, 0, 50)
        // Rotate by -90° around the y-axis (swing open).
        transform = CATransform3DRotate(transform, CGFloat.pi, 0, 1, 0)
        return transform
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Ensure we have the detail VC and the tapped cell.
        guard let toVC = transitionContext.viewController(forKey: .to),
              let selectedIndexPath = gridVC.selectedIndexPath,
              let tappedCell = gridVC.collectionView.cellForItem(at: selectedIndexPath)
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        let container = transitionContext.containerView
        let cellFrame = tappedCell.convert(tappedCell.bounds, to: container)
        let finalFrame = transitionContext.finalFrame(for: toVC)
        
        // Place the detail view exactly over the tapped cell.
        toVC.view.frame = cellFrame
        container.addSubview(toVC.view)
        
        // Animate the other cells in descending order.
        let otherCells = gridVC.collectionView.visibleCells.filter { $0 != tappedCell }
        let sortedCells = otherCells.sorted { cellA, cellB in
            guard let ipA = gridVC.collectionView.indexPath(for: cellA),
                  let ipB = gridVC.collectionView.indexPath(for: cellB)
            else { return false }
            return ipA.item > ipB.item
        }
            
        for (i, cell) in sortedCells.enumerated() {
            let delay = 0.1 * sqrt(Double(i))
            UIView.animate(withDuration: 0.7,
                           delay: delay,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0.0,
                           options: [],
                           animations: {
                               cell.layer.transform = self.doorOpenTransform(for: cell)
                           }, completion: nil)
        }
        
        let detailDelay = 0.0
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: detailDelay,
                       options: [.curveEaseIn],
                       animations: {
                           toVC.view.frame = finalFrame
                       }, completion: nil)
        
        // Complete the transition after the detail view animation finishes.
        DispatchQueue.main.asyncAfter(deadline: .now() + detailDelay + transitionDuration(using: transitionContext)) {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - ReverseZoomPopAnimator

/// The detail view zooms back into the tapped cell while the other cells animate back in
/// by reversing the door-swing effect in descending order.
class ReverseZoomPopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let gridVC: GridViewController

    init(gridVC: GridViewController) {
        self.gridVC = gridVC
        super.init()
    }
 
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }

    func doorOpenTransform(for cell: UIView, in container: UIView) -> CATransform3D {
        var transform = CATransform3DIdentity
        cell.setAnchorPoint(CGPoint(x: 0, y: 0.5))
        transform.m34 = 1.0 / 250.0  // Perspective: d = 250
        
        // Get the index path for the cell and its base midX
        guard let indexPath = gridVC.collectionView.indexPath(for: cell as? UICollectionViewCell ?? UICollectionViewCell()),
              let baseMidX = gridVC.cellBaseMidX[indexPath] else {
            return transform // Return identity if no base midX
        }
        
        // Get the cell's center in container coordinates.
        let cellCenterX = gridVC.collectionView.convert(CGPoint(x: baseMidX, y: 0), to: container).x
        // Instead of doubling, we simply use cellCenterX.
        let mirroredXTranslation = cellCenterX

        // Account for perspective shrinkage.
        let perspectiveDistance: CGFloat = 250.0
        let zTranslation: CGFloat = 500.0
        let scaleFactor = (perspectiveDistance + zTranslation) / perspectiveDistance  // e.g. 750/250 = 3
        let adjustedXTranslation = mirroredXTranslation * scaleFactor
        
        print("Cell \(indexPath.item + 1): cellCenterX = \(cellCenterX), mirroredXTranslation = \(mirroredXTranslation), adjustedXTranslation = \(adjustedXTranslation)")
        
        transform = CATransform3DTranslate(transform, -adjustedXTranslation, 0, zTranslation)
        transform = CATransform3DRotate(transform, -CGFloat.pi, 0, 1, 0)
        return transform
    }

    func animateDoorCell(_ cell: UIView, delay: TimeInterval, container: UIView) {
        let springDuration = transitionDuration(using: nil)
        
        let mass: CGFloat = 1
        let stiffness: CGFloat = 200
        let damping: CGFloat = 40
        let initialVelocity: CGFloat = 0

        guard let indexPath = gridVC.collectionView.indexPath(for: cell as? UICollectionViewCell ?? UICollectionViewCell()),
              let baseMidX = gridVC.cellBaseMidX[indexPath] else {
            return
        }
        
        // Get the cell's center in container coordinates.
        let cellCenterX = gridVC.collectionView.convert(CGPoint(x: baseMidX, y: 0), to: container).x
        // Instead of doubling, we simply use cellCenterX.
        let mirroredXTranslation = cellCenterX

        // Account for perspective shrinkage.
        let perspectiveDistance: CGFloat = 250.0
        let zTranslation: CGFloat = 500.0
        let scaleFactor = (perspectiveDistance + zTranslation) / perspectiveDistance  // e.g. 750/250 = 3
        let adjustedXTranslation = mirroredXTranslation * scaleFactor
        
        let rotationAnim = CASpringAnimation(keyPath: "transform.rotation.y")
        rotationAnim.fromValue = -CGFloat.pi
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
        translationXAnim.fromValue = -adjustedXTranslation
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
        translationZAnim.fromValue = 500
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
            cell.layer.transform = CATransform3DIdentity
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
            let delay = 0.05 * Double(i)
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
