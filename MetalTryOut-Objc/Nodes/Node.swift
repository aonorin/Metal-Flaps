//
//  Model.swift
//  Triangle
//
//  Created by Andrew K. on 6/24/14.
//  Copyright (c) 2014 Andrew Kharchyshyn. All rights reserved.
//
//
//
/////////////////////////////////////////////
//
//  Node class is a base class in game graph, it provides you ability to change transformation of node and all his
//  children. It provide you material specs such as shininess, specularIntensity etc. You should not draw node
//  itself using renderNode, but u should put your node inside Scene and call render(..) on Scene object.
//
//  Usualy Node subclasses are generated from 3D model files however you can take a look at Cube.swift for some 
//  primitive object
//
/////////////////////////////////////////////

import UIKit
import Metal
import QuartzCore


@objc class Node: NSObject
{
    
    var time:CFTimeInterval = 0.0
    
    //initial values
    var baseEffect: BaseEffect
    var name: String
    var vertexCount: Int
    var texture: MTLTexture?
    var depthState: MTLDepthStencilState?
    
    //animation handles
    var positionX:Float = 0.0
    var positionY:Float = 0.0
    var positionZ:Float = 0.0
    var rotationX:Float = 0.0
    var rotationY:Float = 0.0
    var rotationZ:Float = 0.0
    var scaleX:Float    = 1.0
    var scaleY:Float    = 1.0
    var scaleZ:Float    = 1.0
    
    var initialTransformation:AnyObject = Matrix4()
    
    //light specs
    var diffuseIntensity: Float = 1.0
    var ambientIntensity: Float = 1.0
    var specularIntensity: Float = 1.0
    var shininess: Float = 1.0
    
    
    // array of children nodes, you should never add or remove item from it directly, only throu addChild and removeChild
    var children:Array<Node> = Array<Node>()
    var numberOfSiblings: Int = 1
    
    //shaders input data
    var vertexBuffer: MTLBuffer?
    var uniformsBuffer: MTLBuffer?
    var samplerState: MTLSamplerState?
    
    var uniformBufferProvider: AnyObject?
    
    
    init(name: String,
        baseEffect: BaseEffect,
        vertices: Array<Vertex>?,
        vertexCount: Int,
        textureName: String?)
    {
        //Setup texture if present
        if let texName = textureName
        {
            var mTexture:METLTexture = METLTexture(resourceName: texName.pathComponents[0], ext: texName.pathComponents[1])
            mTexture.finalize(baseEffect.device)
            self.texture = mTexture.texture
        }
        
        self.name = name
        self.baseEffect = baseEffect
        self.vertexCount = vertexCount
        
        super.init()
        
        if let trueVertices = vertices
        {
            self.vertexBuffer = generateVertexBuffer(trueVertices, vertexCount: vertexCount, device: baseEffect.device)
        }
        
        self.samplerState = generateSamplerStateForTexture(baseEffect.device)
        
        var depthStateDesc = MTLDepthStencilDescriptor()
        depthStateDesc.depthCompareFunction = MTLCompareFunction.Less
        depthStateDesc.depthWriteEnabled = true
        depthState = baseEffect.device.newDepthStencilStateWithDescriptor(depthStateDesc)
    }
    
    
    //this method is only used by scene object to render it's children recursively
    func renderNode(node: Node, parentMatrix: AnyObject, projectionMatrix: AnyObject, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, encoder: MTLRenderCommandEncoder?) -> MTLRenderCommandEncoder
    {
        var commandEncoder:MTLRenderCommandEncoder
        
        if !encoder
        {
            commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
            commandEncoder.setDepthStencilState(depthState)
            commandEncoder.setRenderPipelineState(baseEffect.renderPipelineState)
            commandEncoder.setFragmentSamplerState(samplerState, atIndex: 0)
            commandEncoder.setCullMode(MTLCullMode.Front)
        }
        else
        {
            commandEncoder = encoder!
        }
        
        
        commandEncoder.pushDebugGroup(node.name)
        
        for child in node.children
        {
            child.renderNode(node, parentMatrix: parentMatrix, projectionMatrix: projectionMatrix, renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, encoder: commandEncoder)
        }
        
        var nodeModelMatrix: Matrix4 = node.modelMatrix() as Matrix4
        nodeModelMatrix.multiplyLeft(parentMatrix as Matrix4)
        var uniform = getUniformsBuffer(nodeModelMatrix, projMatrix: projectionMatrix, baseEffect: node.baseEffect)
        commandEncoder.setVertexBuffer(node.vertexBuffer, offset: 0, atIndex: 0)
        commandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, atIndex: 1)
        commandEncoder.setFragmentTexture(node.texture, atIndex: 0)
        commandEncoder.drawPrimitives(MTLPrimitiveType.Triangle, vertexStart: 0, vertexCount: node.vertexCount)
        
        
        commandEncoder.popDebugGroup()
        
        return commandEncoder
    }
    
    func addChild(child: Node)
    {
        numberOfSiblings += child.numberOfSiblings
        children.append(child)
    }
    
    func removeChild(child: Node)
    {
        numberOfSiblings -= child.numberOfSiblings
        var indexes = Array<Int>()
        for (index, value) in enumerate(children) {
            if value == child
            {
                indexes.append(index)
            }
        }
        for index in indexes
        {
            children.removeAtIndex(index)
        }
        
        children.removeAtIndex(0)
    }
    
    // Transformation
    func setScale(scale: Float)
    {
        scaleX = scale
        scaleY = scale
        scaleZ = scale
    }
    
    func modelMatrix() -> AnyObject //AnyObject is used as a workaround against comiler error, waiting for fix in following betas
    {
        var initialMatCopy: Matrix4 = (initialTransformation as Matrix4).copy()
        var matrix = Matrix4()
        matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
        matrix.translate(positionX, y: positionY, z: positionZ)
        matrix.scale(scaleX, y: scaleY, z: scaleZ)
        matrix.multiplyLeft(initialMatCopy)
//        initialMatCopy.multiplyLeft(matrix)
        return matrix
    }
    
    func updateWithDelta(delta: CFTimeInterval)
    {
        time += delta
        for child in children
        {
            child.updateWithDelta(delta)
        }
    }
    
    // Generators of buffers which are passed to GPU
    func generateSamplerStateForTexture(device: MTLDevice) -> MTLSamplerState?
    {
        var pSamplerDescriptor:MTLSamplerDescriptor? = MTLSamplerDescriptor();
        
        if let sampler = pSamplerDescriptor
        {
            sampler.minFilter             = MTLSamplerMinMagFilter.Nearest
            sampler.magFilter             = MTLSamplerMinMagFilter.Nearest
            sampler.mipFilter             = MTLSamplerMipFilter.NotMipmapped
            sampler.maxAnisotropy         = 1
            sampler.sAddressMode          = MTLSamplerAddressMode.ClampToEdge
            sampler.tAddressMode          = MTLSamplerAddressMode.ClampToEdge
            sampler.rAddressMode          = MTLSamplerAddressMode.ClampToEdge
            sampler.normalizedCoordinates = true
            sampler.lodMinClamp           = 0
            sampler.lodMaxClamp           = FLT_MAX
        }
        else
        {
            println(">> ERROR: Failed creating a sampler descriptor!")
        }
        
        return device.newSamplerStateWithDescriptor(pSamplerDescriptor)
    }
    
    func getUniformsBuffer(mvMatrix: AnyObject, projMatrix: AnyObject,baseEffect: BaseEffect) -> MTLBuffer?
    {
        var mv:Matrix4 = mvMatrix as Matrix4
        var proj:Matrix4 = projMatrix as Matrix4
        var generator: UniformsBufferGenerator = self.uniformBufferProvider as UniformsBufferGenerator
        uniformsBuffer = generator.bufferWithProjectionMatrix(proj, modelViewMatrix: mv, withBaseEffect: baseEffect, withModel: self)
        return uniformsBuffer
    }
    
    func generateVertexBuffer(vertices: Array<Vertex>, vertexCount: Int, device: MTLDevice) -> MTLBuffer?
    {
        vertexBuffer = VertexBufferGenerator.generateBufferVertices(vertices, vertexCount: vertexCount, device: device)
        return vertexBuffer
    }
}
