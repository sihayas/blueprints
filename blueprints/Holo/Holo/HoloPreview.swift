//
//  HoloPreview.swift
//  acusia
//
//  Created by decoherence on 9/9/24.
//
import CoreMotion
import SwiftUI

#Preview {
    HoloPreview()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
}

struct HoloPreview: View {
    private let motionManager = CMMotionManager()
    
    @State private var pitchBaseline: Double = 30
    @State private var rollBaseline: Double = 0
    @State private var isExpanded: Bool = false
    @State private var currentPitch: Double = 0
    @State private var currentRotationX: Float = 30
    
    var body: some View {
        let mkShape = MKSymbolShape(imageName: "helloSticker")
        
        VStack {
            ZStack {
                // Base white layer
                mkShape
                    .stroke(.white,
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round,
                                lineJoin: .round
                            ))
                    .fill(.white)
                    .frame(width: 170, height: 56)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 0)
                    .modifier(Layer3DEffect(
                        isExpanded: isExpanded,
                        yOffset: 0,
                        zIndex: 1
                    ))
                
                // Image layer
                Image("helloSticker")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 170, height: 56)
                    .aspectRatio(contentMode: .fill)
                    .modifier(Layer3DEffect(
                        isExpanded: isExpanded,
                        yOffset: 15,
                        zIndex: 2
                    ))
                
                // Holographic shader layer
                HoloShaderView()
                    .frame(width: 178, height: 178)
                    .mask(
                        mkShape
                            .stroke(.white,
                                    style: StrokeStyle(
                                        lineWidth: 8,
                                        lineCap: .round,
                                        lineJoin: .round
                                    ))
                            .fill(.white)
                            .frame(width: 170, height: 56)
                    )
                    .blendMode(.screen)
                    .opacity(1.0)
                    .modifier(Layer3DEffect(
                        isExpanded: isExpanded,
                        yOffset: 40,
                        zIndex: 3
                    ))
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
            
            // Motion values display
            Text("Pitch: \(currentPitch, specifier: "%.1f")° | Rotation X: \(currentRotationX, specifier: "%.1f")°")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    HoloRotationManager.shared.rotationAngleX = Float(-value.translation.height / 20)
                    HoloRotationManager.shared.rotationAngleY = Float(value.translation.width / 20)
                    currentRotationX = Float(-value.translation.height / 20)
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        HoloRotationManager.shared.rotationAngleX = 30
                        HoloRotationManager.shared.rotationAngleY = 0
                        currentRotationX = 30
                    }
                }
        )
        .onAppear {
            startDeviceMotionUpdates()
        }
    }
    
    struct Layer3DEffect: ViewModifier {
        let isExpanded: Bool
        let yOffset: CGFloat
        let zIndex: Double
        
        func body(content: Content) -> some View {
            content
                .rotation3DEffect(
                    .degrees(isExpanded ? -45 : 0),
                    axis: (x: 0, y: 0, z: 1),
                    anchor: .center,
                    perspective: 0.3
                )
                .rotation3DEffect(
                    .degrees(isExpanded ? 45 : 0),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .center,
                    perspective: 0.3
                )
                .offset(y: isExpanded ? -yOffset : 0)
                .zIndex(zIndex)
        }
    }
    
    func startDeviceMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01
            
            motionManager.startDeviceMotionUpdates(to: .main) { motionData, _ in
                guard let motion = motionData else { return }
                
                let pitch = motion.attitude.pitch * 180 / .pi
                currentPitch = pitch
                
                var adjustedPitch = pitch - pitchBaseline
                
                if adjustedPitch <= -45 {
                    pitchBaseline = pitch
                    adjustedPitch = 30
                } else if adjustedPitch >= 45 {
                    pitchBaseline = pitch
                    adjustedPitch = 30
                }
                
                let shaderValue = clamp(30 + adjustedPitch, -15, 75)
                currentRotationX = Float(shaderValue)
                
                HoloRotationManager.shared.rotationAngleX = Float(shaderValue)
            }
        }
    }
    
    func clamp(_ value: Double, _ minValue: Double, _ maxValue: Double) -> Double {
        return min(max(value, minValue), maxValue)
    }
}
