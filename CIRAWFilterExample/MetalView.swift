//
//  MetalView.swift
//  PHLow
//
//  Created by Владимир Костин on 15.07.2022.
//

import Metal
import MetalKit
import SwiftUI

struct MetalView: UIViewRepresentable {
    
    @StateObject var renderer: Renderer
    
    func makeUIView(context: Context) -> MTKView {
        
        
        renderer.view.preferredFramesPerSecond = 30
        renderer.view.framebufferOnly = false
        renderer.view.backgroundColor = .clear
        renderer.view.delegate = renderer

        return renderer.view
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        
    }

}

class Renderer: NSObject, MTKViewDelegate, ObservableObject {
    
    @Published var ciRAWFilter: CIRAWFilter?
    
    @Published var exposure: Float = 0
    @Published var boostAmount: Float = 0
    @Published var boostShadowAmount: Float = 0
    @Published var neutralTemperature: Float = 0
    @Published var neutralTint: Float = 0
    @Published var shadowBias: Float = 0
    
    let device: MTLDevice
    let view: MTKView
    let commandQueue: MTLCommandQueue
    let cicontext: CIContext
    let inFlightSemaphore = DispatchSemaphore(value: 3)
    
    override init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.view = MTKView(frame: .zero, device: self.device)
        self.commandQueue = self.device.makeCommandQueue()!
        self.cicontext = CIContext(
            mtlCommandQueue: self.commandQueue,
            options: [.name: "Renderer", .cacheIntermediates: true, .allowLowPower: false, .highQualityDownsample: false, .workingFormat: CIFormat.RGBAh])
        super.init()
    }
    
    func draw(in view: MTKView) {

        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            let semaphore = inFlightSemaphore
            commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in semaphore.signal() }
            
            if let drawable = view.currentDrawable {
                
                ciRAWFilter?.exposure = self.exposure
                ciRAWFilter?.boostAmount = self.boostAmount
                ciRAWFilter?.neutralTemperature = self.neutralTemperature
                ciRAWFilter?.neutralTint = self.neutralTint
                ciRAWFilter?.boostShadowAmount = self.boostShadowAmount
                ciRAWFilter?.shadowBias = self.shadowBias
                guard let ciImage = ciRAWFilter?.outputImage else { return }

                let width = Int(view.drawableSize.width)
                let height = Int(view.drawableSize.height)
                let format = view.colorPixelFormat
                
                let destination = CIRenderDestination(width: width, height: height, pixelFormat: format, commandBuffer: commandBuffer, mtlTextureProvider: { () -> MTLTexture in
                    return drawable.texture
                })
                
                var image = ciImage
                
                let scaleFactor = CGFloat(width)/image.extent.size.width
                image = image.transformed(by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
                
                let origin = CGPoint(
                    x: max(image.extent.size.width - CGFloat(width), 0)/2,
                    y: max(image.extent.size.height - CGFloat(height), 0)/2
                )
                
                image = image.cropped(to: CGRect(origin: origin, size: view.drawableSize))
                image = image.transformed(by: CGAffineTransform(translationX: -origin.x, y: -origin.y))
                
                let iRect = image.extent
                let backBounds = CGRect(x: 0, y: 0, width: width, height: height)
                let shiftX = round((backBounds.size.width + iRect.origin.x - iRect.size.width) * 0.5)
                let shiftY = round((backBounds.size.height + iRect.origin.y - iRect.size.height) * 0.5)
                image = image.transformed(by: CGAffineTransform(translationX: shiftX, y: shiftY))
                
                
                do {
                    try self.cicontext.startTask(toClear: destination)
                    try self.cicontext.prepareRender(image, from: backBounds, to: destination, at: CGPoint.zero)
                    try self.cicontext.startTask(toRender: image, from: backBounds, to: destination, at: CGPoint.zero)
                } catch {
                    assertionFailure("Failed to render to preview view: \(error)")
                }
                
                commandBuffer.present(drawable)
                commandBuffer.commit()
            }
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

}
