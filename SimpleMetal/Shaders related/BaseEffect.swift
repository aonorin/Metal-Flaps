//
//  BaseEffect.swift
//  Triangle
//
//  Created by Andrew K. on 6/24/14.
//  Copyright (c) 2014 Andrew Kharchyshyn. All rights reserved.
//

import UIKit
import Metal

@objc class BaseEffect: NSObject
{
    var device:MTLDevice
    var renderPipelineState:MTLRenderPipelineState?
    var pipeLineDescriptor:MTLRenderPipelineDescriptor
    var projectionMatrix:AnyObject = Matrix4()
    
    var lightColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    var lightDirection: [Float] = [0.0,0.0,0.0]
    
    init(device:MTLDevice ,vertexShaderName: String, fragmentShaderName:String)
    {
        self.device = device
        
        // Setup MTLRenderPipline descriptor object with vertex and fragment shader
        pipeLineDescriptor = MTLRenderPipelineDescriptor()
        let library = device.newDefaultLibrary()!
        pipeLineDescriptor.vertexFunction = library.newFunctionWithName(vertexShaderName)
        pipeLineDescriptor.fragmentFunction = library.newFunctionWithName(fragmentShaderName)
        pipeLineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        pipeLineDescriptor.sampleCount = 4
        pipeLineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.Depth32Float
        
        pipeLineDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        pipeLineDescriptor.stencilAttachmentPixelFormat = .Stencil8
        
        super.init()
    }
    
    func compile() -> MTLRenderPipelineState?
    {
        // Compile the MTLRenderPipline object into immutable and cheap for use MTLRenderPipelineState
        renderPipelineState = try! device.newRenderPipelineStateWithDescriptor(pipeLineDescriptor)
        return renderPipelineState!
    }
}
