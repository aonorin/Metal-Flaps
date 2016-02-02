import UIKit

@objc class Ram: Node {

    init(baseEffect: BaseEffect)
    {
        var verticesArray:Array<Vertex> = []
        let path = NSBundle.mainBundle().pathForResource("ram", ofType: "txt")
        let content = try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
        
        var array = content.componentsSeparatedByString("\n")
        array.removeLast()
        for line in array {
            let vertex = Vertex(text: line)
            verticesArray.append(vertex)
        }
        array.removeAll(keepCapacity: false)


        super.init(name: "Ram", baseEffect: baseEffect, vertices: verticesArray, vertexCount: verticesArray.count, textureName: "char_ram_col.jpg")

        verticesArray.removeAll(keepCapacity: false)
        
        self.ambientIntensity = 0.400000
        self.diffuseIntensity = 0.800000
        self.specularIntensity = 0.000000
        self.shininess = 0.098039
        
    }
    
    override func updateWithDelta(delta: CFTimeInterval)
    {
        super.updateWithDelta(delta)
        
        //        rotationZ += Float(M_PI/10) * Float(delta)
//        rotationZ += Float(M_PI/8) * Float(delta)
    }

}