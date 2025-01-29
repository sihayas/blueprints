/// Note Build Rules to get this working properly.

import SwiftUI
import MetalKit
import SceneKit
import SceneKit.ModelIO
import SpriteKit
import CoreImage

struct FragmentUniforms {
    var time: Float
    var cameraPosition: SIMD3<Float>
    var baseColor: SIMD3<Float>
    var roughness: Float
    var iridescenceFactor: Float
    var iridescenceIor: Float
    var iridescenceThicknessMin: Float
    var iridescenceThicknessMax: Float
}

#Preview {
    SoundScreen(
        sound: APIAppleSoundData(
            id: "1",
            type: "song",
            name: "Song Name",
            artistName: "Artist Name",
            albumName: "Album Name",
            releaseDate: "2022-01-01",
            artworkUrl: "https://example",
            artworkBgColor: "#000000",
            identifier: "123",
            trackCount: 1
        )
    )
}


class NormalMapFilter: CIFilter {
    var inputImage: CIImage?
    
    private static var kernel: CIKernel = {
        let url = Bundle.main.url(forResource: "NormalMap", withExtension: "ci.metallib")!
        let data = try! Data(contentsOf: url)
        return try! CIKernel(functionName: "normalMap", fromMetalLibraryData: data)
    }()
    
    override var outputImage: CIImage? {
        guard let input = inputImage else { return nil }
        return NormalMapFilter.kernel.apply(extent: input.extent,
                                            roiCallback: { (index, rect) in
                                                return rect
                                            },
                                            arguments: [input])
    }
}

struct SoundScreen: View {
    let sound: APIAppleSoundData
     
     @State private var scene: SCNScene?
     @State private var ellipsoidNode: SCNNode?
     @State private var isReversing = true
     @State private var showTextAlert = false
     @State private var tempText = ""
     @State private var customText = "LYRA"
     
     @State private var iridescenceFactor: Float = 1.0
     @State private var iridescenceIor: Float = 2.50
     @State private var iridescenceThicknessMin: Float = 100.0
     @State private var iridescenceThicknessMax: Float = 400.0
     @State private var time: Float = 0
     
     let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
     
     var body: some View {
         ZStack {
             if let scene = scene {
                 SceneView(
                     scene: scene,
                     options: [.allowsCameraControl, .autoenablesDefaultLighting],
                     antialiasingMode: .multisampling4X
                 )
                 .ignoresSafeArea()
             } else {
                 ProgressView()
                     .ignoresSafeArea()
             }
             
             VStack {
                 Spacer()
                 
                 VStack(spacing: 24) {
                     // Add text change button
                     Button(action: {
                         tempText = customText  // Initialize temp text with current value
                         showTextAlert = true
                     }) {
                         Text("Change Text")
                             .foregroundColor(.white)
                             .padding(.horizontal, 16)
                             .padding(.vertical, 8)
                             .background(Color.blue)
                             .cornerRadius(8)
                     }
                     .padding(.bottom, 16)
                     
                     HStack(spacing: 20) {
                         SliderControl(
                             title: "Iridescence Factor",
                             value: $iridescenceFactor,
                             range: 0.0...1.0,
                             format: "%.2f",
                             onUpdate: updateMaterial
                         )
                         
                         SliderControl(
                             title: "Iridescence IOR",
                             value: $iridescenceIor,
                             range: 1.0...2.5,
                             format: "%.2f",
                             onUpdate: updateMaterial
                         )
                     }

                     HStack(spacing: 20) {
                         SliderControl(
                             title: "Thickness Min",
                             value: $iridescenceThicknessMin,
                             range: 0.0...1000.0,
                             format: "%.1f",
                             onUpdate: updateMaterial
                         )
                         
                         SliderControl(
                             title: "Thickness Max",
                             value: $iridescenceThicknessMax,
                             range: 0.0...1000.0,
                             format: "%.1f",
                             onUpdate: updateMaterial
                         )
                     }
                 }
                 .padding(24)
             }
         }
         .alert("Change Display Text", isPresented: $showTextAlert) {
             TextField("Enter new text", text: $tempText)
             Button("Cancel", role: .cancel) {
                 tempText = customText  // Reset temp text
             }
             Button("Update") {
                 if !tempText.isEmpty {
                     customText = tempText
                     setupScene()  // Only re-render when user confirms
                 }
             }
         } message: {
             Text("Enter the text you want to display")
         }
         .onAppear(perform: setupScene)
         .onReceive(timer) { _ in
             time += 1/60
             updateMaterial()
         }
     }
    
    private func setupScene() {
        self.scene = createScene()
    }
    
    private func updateMaterial() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        
        let uniformBuffer = device.makeBuffer(length: MemoryLayout<FragmentUniforms>.stride, options: [])!
        var uniforms = FragmentUniforms(
            time: time,
            cameraPosition: SIMD3<Float>(0, 0, 0),
            baseColor: SIMD3<Float>(0.0, 0.0, 0.0),
            roughness: 0.1,
            iridescenceFactor: iridescenceFactor,
            iridescenceIor: iridescenceIor,
            iridescenceThicknessMin: iridescenceThicknessMin,
            iridescenceThicknessMax: iridescenceThicknessMax
        )
        uniformBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<FragmentUniforms>.stride)
        
        ellipsoidNode?.geometry?.firstMaterial?.setValue(uniformBuffer, forKey: "uniforms")
    }
    
    private func flipEllipsoid() {
        guard let ellipsoidNode = ellipsoidNode else { return }
        let flipAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi, z: 0, duration: 0.5)
        ellipsoidNode.runAction(flipAction)
    }
}


// MARK: - Scene Setup
extension SoundScreen {
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.black

        let discDiameter: CGFloat = 4
        let discThickness: CGFloat = 0.4

        // Create disc mesh
        let allocator = MTKMeshBufferAllocator(device: MTLCreateSystemDefaultDevice()!)
        let disc = MDLMesh.newEllipsoid(
            withRadii: vector_float3(Float(discDiameter / 2), Float(discDiameter / 2), Float(discThickness)),
            radialSegments: 64,
            verticalSegments: 64,
            geometryType: .triangles,
            inwardNormals: false,
            hemisphere: false,
            allocator: allocator
        )
        // Needed for normal map with shader.
        disc.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                             tangentAttributeNamed: MDLVertexAttributeTangent,
                             bitangentAttributeNamed: MDLVertexAttributeBitangent)

        let discGeometry = SCNGeometry(mdlMesh: disc)
        guard let normalMap = createNormalMap(size: CGSize(width: 1000, height: 500)) else {
            fatalError("Failed to create text image")
        }
        let material = createIridescence(normalMap: normalMap)
        discGeometry.materials = [material]

        let ellipsoidNode = SCNNode(geometry: discGeometry)
        self.ellipsoidNode = ellipsoidNode
        
        let ellipsoidParentNode = SCNNode()
        ellipsoidParentNode.addChildNode(ellipsoidNode)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 18)
        cameraNode.camera!.fieldOfView = 30
        cameraNode.camera!.zNear = 1
        cameraNode.camera!.zFar = 100
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(ellipsoidParentNode)

        ellipsoidParentNode.scale = SCNVector3(1.0, 1.0, 1.0)
        ellipsoidParentNode.position = SCNVector3(0, 0, 0)
        ellipsoidParentNode.eulerAngles.y = Float.pi * 0.2

        playAnimationSequence(ellipsoidNode: ellipsoidParentNode, isReversing: isReversing)

        return scene
    }

    private func createIridescence(normalMap: CGImage) -> SCNMaterial {
        let material = SCNMaterial()

        guard let device = MTLCreateSystemDefaultDevice(),
              let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            fatalError("Failed to create Metal device, default library, or shader functions")
        }

        let program = SCNProgram()
        program.vertexFunctionName = "vertexShader"
        program.fragmentFunctionName = "fragmentShader"
        material.program = program

        // Set up parameters
        let uniformBuffer = device.makeBuffer(length: MemoryLayout<FragmentUniforms>.stride, options: [])!
        var uniforms = FragmentUniforms(
            time: time,
            cameraPosition: SIMD3<Float>(0, 0, 0),
            baseColor: SIMD3<Float>(1.0, 1.0, 1.0),
            roughness: 0.1,
            iridescenceFactor: iridescenceFactor,
            iridescenceIor: iridescenceIor,
            iridescenceThicknessMin: iridescenceThicknessMin,
            iridescenceThicknessMax: iridescenceThicknessMax
        )
        uniformBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<FragmentUniforms>.stride)

        // Create time buffer
        let timeBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])!

        // Set up material
        material.setValue(uniformBuffer, forKey: "uniforms")
        material.setValue(timeBuffer, forKey: "timeBuffer")
        let normalMapProperty = SCNMaterialProperty(contents: normalMap)
        material.setValue(normalMapProperty, forKey: "normalMap")

        return material
    }
    
    private func createNormalMap(size: CGSize) -> CGImage? {
        let offsetToFront: CGFloat = 250.0
        
        let image = UIGraphicsImageRenderer(size: size).image { context in
              UIColor.black.setFill()
              context.fill(CGRect(origin: .zero, size: size))

              let secondText = customText // Use the customText state variable instead of hardcoded "LYRA"
              let secondTextAttributes: [NSAttributedString.Key: Any] = [
                  .font: UIFont.systemFont(ofSize: 15, weight: .thin),
                  .foregroundColor: UIColor.white,
                  .kern: 3.0
              ]

              let secondTextSize = (secondText as NSString).size(withAttributes: secondTextAttributes)
              
              // Calculate the starting Y position to center the text
              let startingY = (size.height - secondTextSize.height) / 2

              let secondTextRect = CGRect(
                  x: (size.width - secondTextSize.width) / 2 + offsetToFront,
                  y: startingY,
                  width: secondTextSize.width,
                  height: secondTextSize.height
              )

              context.cgContext.translateBy(x: size.width, y: size.height)
              context.cgContext.scaleBy(x: -1.0, y: -1.0)

              secondText.draw(in: secondTextRect, withAttributes: secondTextAttributes)
          }
        guard let ciImage = CIImage(image: image),
              let blurredImage = CIFilter(name: "CIGaussianBlur", parameters: [
                kCIInputImageKey: ciImage,
                kCIInputRadiusKey: 0.0
              ])?.outputImage?.cropped(to: ciImage.extent),
              let invertedImage = CIFilter(name: "CIColorInvert", parameters: [
                kCIInputImageKey: blurredImage
              ])?.outputImage?.cropped(to: blurredImage.extent) else {
            print("Failed to process image")
            return nil
        }

        let normalMapFilter = NormalMapFilter()
        normalMapFilter.inputImage = invertedImage

        guard let normalMapOutput = normalMapFilter.outputImage,
              let cgImage = CIContext().createCGImage(normalMapOutput, from: normalMapOutput.extent) else {
            print("Failed to process image")
            return nil
        }

        return cgImage
    }

}


struct SliderControl: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let format: String
    let onUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Text(String(format: format, value))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Slider(value: $value, in: range)
                .tint(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .onChange(of: value) { _ in onUpdate() }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Animation Helpers
extension SoundScreen {
    func playAnimationSequence(ellipsoidNode: SCNNode, isReversing: Bool) {
        playForwardAnimation(ellipsoidNode: ellipsoidNode)
    }
    
    private func playForwardAnimation(ellipsoidNode: SCNNode) {
        let animateCombined = SCNAction.customAction(duration: 1.5) { node, elapsedTime in
            let progress = Float(elapsedTime) / 1.5
            let easeProgress = self.customEaseOut(progress)
            
            // Scale and move normally
            let scale = 0.0 + (1 - 0.0) * easeProgress
            node.scale = SCNVector3(scale, scale, scale)
            node.position.x = 0
            node.position.y = 2
            
            // Rotation with independent control
            let rotationProgress = Float(elapsedTime) / 1.0
            let easedRotationProgress = self.customRotationEaseOut(min(rotationProgress, 1))
            let initialTilt = Float.pi * 0.2  // Initial tilt (36 degrees)
            let additionalRotation = Float.pi * 0.001  // Additional 72 degrees
            let totalRotation = initialTilt + additionalRotation
            let rotation = initialTilt - easedRotationProgress * totalRotation
            
            node.eulerAngles.y = rotation
        }
        
        let sequence = SCNAction.sequence([animateCombined])
        
        ellipsoidNode.removeAllActions()
        ellipsoidNode.runAction(sequence)
    }
    
    // Rapid ease out for scaling and translating in
    private func customEaseOut(_ t: Float) -> Float {
        return 1 - pow(1 - t, 5)  // Increased power for faster initial movement
    }

    private func customRotationEaseOut(_ t: Float) -> Float {
        // Start slow, accelerate in the middle, then slow down at the end
        if t < 0.5 {
            // Slow start (ease-in)
            return 2 * t * t
        } else {
            // Slow end (ease-out)
            return 1 - pow(-2 * t + 2, 2) / 2
        }
    }
}


extension UIImage {
    func convertToGrayscale() -> UIImage {
        let ciImage = CIImage(image: self)
        let grayscale = ciImage?.applyingFilter("CIColorControls", parameters: ["inputSaturation": 0.0])
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(grayscale!, from: grayscale!.extent)
        return UIImage(cgImage: cgImage!)
    }
}

struct APIAppleSoundData: Codable, Hashable {
    let id: String
    let type: String
    let name: String
    let artistName: String
    let albumName: String?
    let releaseDate: String
    let artworkUrl: String
    let artworkBgColor: String
    let identifier: String
    let trackCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, type, name
        case artistName = "artist_name"
        case albumName = "album_name"
        case releaseDate = "release_date"
        case artworkUrl = "artwork_url"
        case artworkBgColor = "artwork_bgColor"
        case identifier
        case trackCount = "track_count"
    }
}
