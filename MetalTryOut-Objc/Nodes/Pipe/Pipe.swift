import UIKit

@objc class Pipe: Node {

    init(baseEffect: BaseEffect)
    {

        var verticesArray:Array<Vertex> = []
        let path = NSBundle.mainBundle().pathForResource("pipe", ofType: "txt")
        let content = try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)

        var array = content.componentsSeparatedByString("\n")
        array.removeLast()
        for line in array {
            let vertex = Vertex(text: line)
            verticesArray.append(vertex)
        }

        super.init(name: "Pipe", baseEffect: baseEffect, vertices: verticesArray, vertexCount: verticesArray.count, textureName: "pip.png")

        self.ambientIntensity = 0.800000
        self.diffuseIntensity = 0.700000
        self.specularIntensity = 0.800000
        self.shininess = 8.078431

        
        self.setScale(0.5)
    }
    
    
    override func updateWithDelta(delta: CFTimeInterval)
    {
        super.updateWithDelta(delta)
//        rotationZ += Float(M_PI/2) * Float(delta)
    }

}