//
//  Scene.swift
//  Imported Model
//
//  Created by Andrew K. on 7/4/14.
//  Copyright (c) 2014 Andrew Kharchyshyn. All rights reserved.
//

import UIKit

class Scene: Node {

    
    var avaliableUniformBuffers: dispatch_semaphore_t?
    
    var width: Float = 0.0
    var height: Float = 0.0
    
    let perspectiveAngleRad: Float = Matrix4.degreesToRad(85.0)
    var sceneOffsetZ: Float = 0.0
    
//    var projectionMatrix: AnyObject
    
    init(name: String, baseEffect: BaseEffect, width: Float, height: Float)
    {
        self.width = width
        self.height = height
        
        sceneOffsetZ = (height * 0.5) / tanf(perspectiveAngleRad * 0.5)
        let ratio: Float = Float(width) / Float(height)
        
    
        baseEffect.projectionMatrix = Matrix4.makePerspectiveViewAngle(perspectiveAngleRad, aspectRatio: ratio, nearZ: 0.1, farZ: 10.5*sceneOffsetZ)
        
        super.init(name: name, baseEffect: baseEffect, vertices: nil, vertexCount: 0, textureName: nil)
        
        positionZ = -1*sceneOffsetZ
    }
    
    func prepareToDraw()
    {
        let numberOfUniformBuffersToUse = 3*self.numberOfSiblings
        print("bufs \(numberOfUniformBuffersToUse)")
        avaliableUniformBuffers = dispatch_semaphore_create(numberOfUniformBuffersToUse)
        self.uniformBufferProvider = UniformsBufferGenerator(numberOfInflightBuffers: CInt(numberOfUniformBuffersToUse), withDevice: baseEffect.device)
        
    }
    
    func render(commandQueue: MTLCommandQueue, metalView: MetalView, parentMVMatrix: AnyObject)
    {
        
        let parentModelViewMatrix: Matrix4 = parentMVMatrix as! Matrix4
        let myModelViewMatrix: Matrix4 = modelMatrix() as! Matrix4
        myModelViewMatrix.multiplyLeft(parentModelViewMatrix)
        let projectionMatrix: Matrix4 = baseEffect.projectionMatrix as! Matrix4
        
        
        //We are using 3 uniform buffers, we need to wait in case CPU wants to write in first uniform buffer, while GPU is still using it (case when GPU is 2 frames ahead CPU)
        dispatch_semaphore_wait(avaliableUniformBuffers!, DISPATCH_TIME_FOREVER)
        
        
        let renderPathDescriptor = metalView.frameBuffer.renderPassDescriptor
        let commandBuffer = commandQueue.commandBuffer()
        commandBuffer.addCompletedHandler(
            {
                (buffer:MTLCommandBuffer!) -> Void in
                _ = dispatch_semaphore_signal(self.avaliableUniformBuffers!)
            })
        
        
        _ = vertexCount <= 0
        var commandEncoder: MTLRenderCommandEncoder? = nil
        
        for var i = 0; i < children.count; i++
        {
            let child = children[i]
            _ = i == children.count - 1
            commandEncoder = renderNode(child, parentMatrix: myModelViewMatrix, projectionMatrix: projectionMatrix, renderPassDescriptor: renderPathDescriptor, commandBuffer: commandBuffer, encoder: commandEncoder, uniformProvider: uniformBufferProvider)
        }
        
        if let drawableAnyObject = metalView.frameBuffer.currentDrawable
        {
            commandBuffer.presentDrawable(drawableAnyObject);
        }
        
        commandEncoder?.endEncoding()
        
        // Commit commandBuffer to his commandQueue in which he will be executed after commands before him in queue
        commandBuffer.commit();
    }
}
