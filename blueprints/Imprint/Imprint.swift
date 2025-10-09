//
//  ImprintPreview.swift
//  blueprints
//
//  Created by decoherence on 1/12/25.
//
/// A SwiftUI prototype for experimenting with interactive card decks,
/// morphing vector shapes, and animated gestures.
///
/// - Uses `BigUIPaging` for card deck pagination with custom shadowing.
/// - Integrates `Wave`’s spring animator for drag-based throw physics.
/// - Demonstrates morphing between circle and heart paths using
///   `AnimatableVector` and custom shape interpolation.
/// - Adds ripple, heartbeat, and heartbreak keyframe effects to highlight
///   transitions triggered by swipe gestures.
///
/// The intention is to explore fluid, playful motion design
/// for previews and micro-interactions.
//

import BigUIPaging
import SwiftUI
import Wave

#Preview {
    ImprintPreview()
}

struct ImprintPreview: View {
    // Card Deck
    @State private var selection: Int = 1

    // Wave
    let offsetAnimator = SpringAnimator<CGPoint>(spring: .defaultInteractive)
    let interactiveSpring = Spring(dampingRatio: 0.8, response: 0.26)
    let animatedSpring = Spring(dampingRatio: 0.72, response: 0.7)
    @State var shapeOffset: CGPoint = .zero
    @State var shapeTargetPosition: CGPoint = .zero
    @State var shapeInitialPosition: CGPoint = .zero

    // Morph
    @State var controlPoints: AnimatableVector = circleControlPoints
    @State var morphShape = false

    // Keyframe Animations
    @State var showKeyframeShape = [false, false] // Left, Right
    @State var keyframeTrigger: Int = 0

    // Ripple Shader
    @State var rippleTrigger: Int = 0
    @State var origin: CGPoint = .zero
    @State private var velocity: CGFloat = 1.0

    var body: some View {
        let imageUrl = "https://is1-ssl.mzstatic.com/image/thumb/Video211/v4/65/14/2c/65142c17-4e8d-3049-0272-363307f09160/Job269ee82f-3d63-436c-bbf6-14db5a51e33b-183757043-PreviewImage_Preview_Image_Intermediate_nonvideo_sdr_359319945_2021523669-Time1736908482381.png/632x632bb.webp"
        let name = "Balloonerism"
        let artistName = "Mac Miller"

        VStack {
            // Card stack
            PageView(selection: $selection) {
                ForEach([1, 2], id: \.self) { index in
                    if index == 1 {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(Color(UIColor.systemGray6))
                                .overlay {
                                    ZStack(alignment: .bottomTrailing) {
                                        VStack {
                                            Text("I’m sure we all cried at some point in the album, but the piano on “Funny Papers” & “Excelsior” broke me ⛓️‍💥🌱")
                                                .foregroundColor(.white)
                                                .font(.system(size: 15, weight: .semibold))
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding([.horizontal, .top], 20)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        .mask(
                                            LinearGradient(
                                                gradient: Gradient(stops: [
                                                    .init(color: .black, location: 0),
                                                    .init(color: .black, location: 0.75),
                                                    .init(color: .clear, location: 0.825)
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            .frame(height: .infinity)
                                        )
                                        
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(artistName)
                                                    .foregroundColor(.secondary)
                                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                                    .lineLimit(1)
                                                Text(name)
                                                    .foregroundColor(.secondary)
                                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                            
                                            // Reserve space for shape to animate to.
                                            GeometryReader { geo in
                                                Rectangle()
                                                    .fill(.clear)
                                                    .frame(width: 28, height: 28)
                                                    .onAppear {
                                                        // Capture the position of the target for the shape
                                                        shapeTargetPosition = CGPoint(x: geo.frame(in: .global).minX, y: geo.frame(in: .global).minY)
                                                    }
                                            }
                                            .frame(width: 28, height: 28) // Limit GeometryReader size
                                        }
                                        .padding(20)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                    }
                                }
                                .frame(height: 280)
                                .modifier(RippleEffect(at: origin, trigger: rippleTrigger, velocity: velocity))
                                .onAppear {
                                    // Capture the bottom-right position for the ripple effect
                                    let frame = geo.frame(in: .global)
                                    let bottomTrailing = CGPoint(x: frame.maxX, y: frame.maxY)
                                    origin = bottomTrailing
                                }
                        }
                    } else {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .background(.clear)
                            .overlay(alignment: .bottom) {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                                } placeholder: {
                                    Rectangle()
                                }
                            }
                    }
                }
            }
            .pageViewStyle(.customCardDeck)
            .pageViewCardShadow(.visible)
            .frame(width: 204, height: 280)

            Spacer()
                .frame(width: 32, height: 124)

            ZStack {
                GeometryReader { geo in
                    MorphableShape(controlPoints: self.controlPoints)
                        .fill(.white)
                        .frame(width: morphShape ? 28 : 72, height: morphShape ? 28 : 72)
                        .onAppear {
                            // Capture the initial position of the blue rectangle
                            shapeInitialPosition = CGPoint(x: geo.frame(in: .global).minX, y: geo.frame(in: .global).minY)
                        }
                        .opacity(showKeyframeShape.contains(true) ? 0 : 1)

                    // Quickly transition to a keyframe heart.
                    Group {
                        if showKeyframeShape[0] {
                            HeartbreakLeftPath()
                                .stroke(.white, lineWidth: 1)
                                .fill(.white)
                                .frame(width: 28, height: 28)
                                .applyHeartbreakLeftAnimator(triggerKeyframe: keyframeTrigger)
                                .opacity(1)

                            HeartbreakRightPath()
                                .stroke(.white, lineWidth: 1)
                                .fill(.white)
                                .frame(width: 28, height: 28)
                                .applyHeartbreakRightAnimator(triggerKeyframe: keyframeTrigger)
                                .opacity(1)
                        } else if showKeyframeShape[1] {
                            HeartPath()
                                .stroke(.white, lineWidth: 1)
                                .fill(.white)
                                .frame(width: 28, height: 28)
                                .applyHeartbeatAnimator(triggerKeyframe: keyframeTrigger)
                                .opacity(1)
                        }
                    }
                    .onAppear {
                        keyframeTrigger += 1
                        rippleTrigger += 1
                    }
                    .onTapGesture {
                        // Reset the animator to the original position
                        offsetAnimator.spring = interactiveSpring
                        offsetAnimator.target = .zero

                        // Use animated mode to animate the transition.
                        offsetAnimator.mode = .animated
                        offsetAnimator.start()

                        withAnimation(.easeOut(duration: 0.3)) {
                            morphShape = false
                            self.controlPoints = circleControlPoints
                            showKeyframeShape = [false, false]
                        }
                    }
                }
                .frame(width: 80, height: 80) 
            }
            .offset(x: shapeOffset.x, y: shapeOffset.y)
            .onAppear {
                // Initialize wave animator
                offsetAnimator.value = .zero

                // The offset animator's callback will update the `offset` state variable.
                offsetAnimator.valueChanged = { newValue in
                    shapeOffset = newValue
                }

                offsetAnimator.completion = { event in
                    switch event {
                    case .finished(let finalValue):
                        // Update blue rectangle position after the animation fully completes
                        print("Animation finished at value: \(finalValue)")

                    case .retargeted(let from, let to):
                        // Log the retarget event or handle if necessary
                        print("Animation retargeted from: \(from) to: \(to)")
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Update the animator's target to the new drag translation.
                        offsetAnimator.spring = interactiveSpring
                        offsetAnimator.target = CGPoint(x: value.translation.width, y: value.translation.height)
                        offsetAnimator.mode = .animated
                        offsetAnimator.start()
                    }
                    .onEnded { value in
                        // Use the instantaneous velocity provided by the gesture
                        let velocityX = value.velocity.width
                        let velocityY = value.velocity.height
                        let velocityMagnitude = hypot(velocityX, velocityY)

                        // Pass to the Ripple shader for impact
                        self.velocity = velocityMagnitude / 1000

                        // Thresholds for a quick swipe
                        let minimumVelocity: CGFloat = 750 // points per second

                        if velocityMagnitude >= minimumVelocity {
                            offsetAnimator.spring = animatedSpring

                            // Calculate the difference between the target and initial positions
                            let targetOffset = CGPoint(
                                x: shapeTargetPosition.x - shapeInitialPosition.x,
                                y: shapeTargetPosition.y - shapeInitialPosition.y
                            )

                            // Assign this offset as the new target for the animator
                            offsetAnimator.target = targetOffset

                            // Use animated mode to animate the transition.
                            offsetAnimator.mode = .animated

                            // Assign the gesture velocity to the animator to ensure a natural throw feel.
                            offsetAnimator.velocity = CGPoint(x: velocityX, y: velocityY)
                            offsetAnimator.start()

                            withAnimation(.easeOut(duration: 0.3)) {
                                // Shrink the circle
                                morphShape.toggle()

                                // Morph circle into a heart
                                self.controlPoints = heartControlPoints

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    if velocityX < 0 {
                                        // Left swipe
                                        showKeyframeShape[0] = true
                                    } else if velocityX > 0 {
                                        // Right swipe
                                        showKeyframeShape[1] = true
                                    }
                                }
                            }
                        } else {
                            // Reset the animator to the original position
                            offsetAnimator.spring = interactiveSpring
                            offsetAnimator.target = .zero

                            // Use animated mode to animate the transition.
                            offsetAnimator.mode = .animated

                            // Assign the gesture velocity to the animator to ensure a natural throw feel.
                            offsetAnimator.velocity = CGPoint(x: velocityX, y: velocityY)

                            offsetAnimator.start()
                        }
                    }
            )
        }
    }

    var indicatorSelection: Binding<Int> {
        .init {
            selection - 1
        } set: { newValue in
            selection = newValue + 1
        }
    }
}


struct AnimatableVector: VectorArithmetic {
    
    var values: [Double] // vector values
    
    init(count: Int = 1) {
        self.values = [Double](repeating: 0.0, count: count)
        self.magnitudeSquared = 0.0
    }
    
    init(with values: [Double]) {
        self.values = values
        self.magnitudeSquared = 0
        self.recomputeMagnitude()
    }
    
    func computeMagnitude()->Double {
        // compute square magnitued of the vector
        // = sum of all squared values
        var sum: Double = 0.0
        
        for index in 0..<self.values.count {
            sum += self.values[index]*self.values[index]
        }
        
        return Double(sum)
    }
    
    mutating func recomputeMagnitude(){
        self.magnitudeSquared = self.computeMagnitude()
    }
    
    // MARK: VectorArithmetic
    var magnitudeSquared: Double // squared magnitude of the vector
    
    mutating func scale(by rhs: Double) {
        // scale vector with a scalar
        // = each value is multiplied by rhs
        for index in 0..<values.count {
            values[index] *= rhs
        }
        self.magnitudeSquared = self.computeMagnitude()
    }
    
    // MARK: AdditiveArithmetic
    
    // zero is identity element for aditions
    // = all values are zero
    static var zero: AnimatableVector = AnimatableVector()
    
    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        var retValues = [Double]()
        
        for index in 0..<min(lhs.values.count, rhs.values.count) {
            retValues.append(lhs.values[index] + rhs.values[index])
        }
        
        return AnimatableVector(with: retValues)
    }
    
    static func += (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        for index in 0..<min(lhs.values.count,rhs.values.count)  {
            lhs.values[index] += rhs.values[index]
        }
        lhs.recomputeMagnitude()
    }

    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        var retValues = [Double]()
        
        for index in 0..<min(lhs.values.count, rhs.values.count) {
            retValues.append(lhs.values[index] - rhs.values[index])
        }
        
        return AnimatableVector(with: retValues)
    }
    
    static func -= (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        for index in 0..<min(lhs.values.count,rhs.values.count)  {
            lhs.values[index] -= rhs.values[index]
        }
        lhs.recomputeMagnitude()
    }
}

let circleControlPoints: AnimatableVector = Circle().path(in: CGRect(x: 0, y: 0, width: 1, height: 1))
    .controlPoints(count: 500)
let heartControlPoints: AnimatableVector = HeartPath().path(in: CGRect(x: 0, y: 0, width: 1, height: 1))
    .controlPoints(count: 500)


struct MorphableShape: Shape {
    var controlPoints: AnimatableVector
    
    var animatableData: AnimatableVector {
        set { self.controlPoints = newValue }
        get { return self.controlPoints }
    }
    
    func point(x: Double, y: Double, rect: CGRect) -> CGPoint {
        // vector values are expected to by in the range of 0...1
        return CGPoint(x: Double(rect.width)*x, y: Double(rect.height)*y)
    }
    
    func path(in rect: CGRect) -> Path {
        return Path { path in
            
            path.move(to: self.point(x: self.controlPoints.values[0],
                                     y: self.controlPoints.values[1], rect: rect))
            
            var i = 2
            while i < self.controlPoints.values.count - 1 {
                path.addLine(to: self.point(x: self.controlPoints.values[i],
                                            y: self.controlPoints.values[i + 1], rect: rect))
                i += 2
            }
            
            path.addLine(to: self.point(x: self.controlPoints.values[0],
                                        y: self.controlPoints.values[1], rect: rect))
        }
    }
}


extension Path {
    // return point at the curve
    func point(at offset: CGFloat) -> CGPoint {
        let limitedOffset = min(max(offset, 0), 1)
        guard limitedOffset > 0 else { return cgPath.currentPoint }
        return trimmedPath(from: 0, to: limitedOffset).cgPath.currentPoint
    }
    
    // return control points along the path
    func controlPoints(count: Int) -> AnimatableVector {
        var retPoints = [Double]()
        for index in 0..<count {
            let pathOffset = Double(index) / Double(count)
            let pathPoint = self.point(at: CGFloat(pathOffset))
            retPoints.append(Double(pathPoint.x))
            retPoints.append(Double(pathPoint.y))
        }
        return AnimatableVector(with: retPoints)
    }
}
