//
//  HoloShaderView.swift
//  acusia
//
//  Created by decoherence on 9/12/24.
//
import MetalKit
import SwiftUI

struct HoloUniforms {
    var modelMatrix: simd_float4x4
    var viewProjectionMatrix: simd_float4x4
    var lightDirection: simd_float3
    var padding: Float = 0
    var rotationAngleX: Float
    var rotationAngleY: Float
}

struct HoloShaderView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = HoloResourceManager.shared.device
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60 // Optimized FPS
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // No updates needed here
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: HoloShaderView
        let commandQueue: MTLCommandQueue
        
        init(_ parent: HoloShaderView) {
            self.parent = parent
            self.commandQueue = HoloResourceManager.shared.createCommandQueue()
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
            else { return }
            
            // Use the shared uniform buffer
            renderEncoder.setRenderPipelineState(HoloResourceManager.shared.pipelineState)
            renderEncoder.setVertexBuffer(HoloResourceManager.shared.vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(HoloResourceManager.shared.uniformBuffer, offset: 0, index: 1)
            renderEncoder.setFragmentBuffer(HoloResourceManager.shared.uniformBuffer, offset: 0, index: 1)
            renderEncoder.setFragmentTexture(HoloResourceManager.shared.rampTexture, index: 0)
            renderEncoder.setFragmentTexture(HoloResourceManager.shared.noiseTexture, index: 1)
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: HoloResourceManager.shared.indexBuffer, indexBufferOffset: 0)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
