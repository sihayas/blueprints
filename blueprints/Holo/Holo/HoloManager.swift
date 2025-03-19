//
//  HoloManager.swift
//  acusia
//
//  Created by decoherence on 9/11/24.
//
import MetalKit
import SwiftUI
import Foundation
import Combine

// MARK: - Manage pitch/roll values in one shared place
class HoloRotationManager: ObservableObject {
    static let shared = HoloRotationManager()
    
    @Published var rotationAngleX: Float = 0
    @Published var rotationAngleY: Float = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        $rotationAngleX
            .combineLatest($rotationAngleY)
            .sink { angleX, angleY in
                HoloResourceManager.shared.updateUniformBuffer(rotationX: angleX, rotationY: angleY)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Manage Metal resources in one shared place
class HoloResourceManager {
    static let shared = HoloResourceManager()
    
    let device: MTLDevice
    let defaultCommandQueue: MTLCommandQueue
    let pipelineState: MTLRenderPipelineState
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let rampTexture: MTLTexture
    let noiseTexture: MTLTexture
    var uniformBuffer: MTLBuffer!
    
    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        
        do {
            // Load the default Metal library
            let library = device.makeDefaultLibrary()
            let vertexFunction = library?.makeFunction(name: "vertex_main")
            let fragmentFunction = library?.makeFunction(name: "fragment_main")
            
            // Create the pipeline state
            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float3
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0
            vertexDescriptor.attributes[1].format = .float2
            vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 3
            vertexDescriptor.attributes[1].bufferIndex = 0
            vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 5
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            pipelineDescriptor.vertexDescriptor = vertexDescriptor
            
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            self.defaultCommandQueue = device.makeCommandQueue()!
            
            // Vertex data
            let vertexData: [Float] = [
                -1.0, -1.0, 0.0, 0.0, 1.0,
                1.0, -1.0, 0.0, 1.0, 1.0,
                -1.0, 1.0, 0.0, 0.0, 0.0,
                1.0, 1.0, 0.0, 1.0, 0.0
            ]
            guard let vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: []) else {
                fatalError("Failed to create vertex buffer")
            }
            self.vertexBuffer = vertexBuffer
            
            // Index data
            let indexData: [UInt16] = [0, 1, 2, 2, 1, 3]
            guard let indexBuffer = device.makeBuffer(bytes: indexData, length: indexData.count * MemoryLayout<UInt16>.size, options: []) else {
                fatalError("Failed to create index buffer")
            }
            self.indexBuffer = indexBuffer
            
            // Load ramp and noise textures
            let textureLoader = MTKTextureLoader(device: device)
            let options: [MTKTextureLoader.Option: Any] = [.SRGB: false]
            self.rampTexture = try textureLoader.newTexture(name: "ramp", scaleFactor: 1.0, bundle: nil, options: nil)
            self.noiseTexture = try textureLoader.newTexture(name: "noise3", scaleFactor: 1.0, bundle: nil, options: nil)
            
            // Create the shared uniform buffer
            self.uniformBuffer = device.makeBuffer(length: MemoryLayout<HoloUniforms>.stride, options: [])
            
        } catch {
            fatalError("Failed to create pipeline state, buffers, or textures: \(error.localizedDescription)")
        }
    }
    
    // Method to create a new command queue
    func createCommandQueue() -> MTLCommandQueue {
        return device.makeCommandQueue()!
    }
    
    // Method to update the shared uniform buffer
    func updateUniformBuffer(rotationX: Float, rotationY: Float) {
        var uniforms = HoloUniforms(
            modelMatrix: matrix_identity_float4x4,
            viewProjectionMatrix: matrix_identity_float4x4,
            lightDirection: simd_normalize(simd_float3(1, 1, -1)),
            rotationAngleX: rotationX,
            rotationAngleY: rotationY
        )
        self.uniformBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<HoloUniforms>.size)
    }
}
