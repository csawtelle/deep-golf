//
//  ContentView.swift
//  ARStarter
//
//  Created by Chris Sawtelle on 12/16/21.
//

import SwiftUI
import RealityKit
import ARKit

class BodySkeleton: Entity {
    var joints: [String: Entity] = [:] // map joint names to entities
    required init(for bodyAnchor: ARBodyAnchor) {
        super.init()
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            let jointRadius: Float = 0.03
            let jointColor: UIColor = .green
            
            let jointEntity = makeJoint(radius: jointRadius, color: jointColor)
            joints[jointName] = jointEntity
            self.addChild(jointEntity)
        }
        
        self.update(with: bodyAnchor)
    }
    
    required init() { // TODO: Remove
        fatalError("init() has not been implemented")
    }
    
    func makeJoint(radius: Float, color: UIColor) -> Entity{
        let mesh = MeshResource.generateSphere(radius:radius)
        let material = SimpleMaterial(color: color, roughness: 0.8, isMetallic: false)
        let modelEntity = ModelEntity(mesh:mesh, materials: [material])
        
        return modelEntity
    }
    
    func update(with bodyAnchor: ARBodyAnchor) {
        let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            if let jointEntity = joints[jointName], let jointTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)) {
                
                let jointOffset = simd_make_float3(jointTransform.columns.3)
                
                jointEntity.position = rootPosition + jointOffset
                
                jointEntity.orientation = Transform(matrix: jointTransform).rotation
                
            }
        }
    }
}


struct ContentView : View { // Controls what the viewer is seeing
    var body: some View {
        VStack(alignment: .leading) { // Vertical stacking objects
            Text("Hello World")
            HStack { // Horizontal stacking objects
                ARViewContainer().frame(width: 400.0, height: 400.0).edgesIgnoringSafeArea(.all) // Viewport for AR
            }
        }
    }
}

var bodySkeleton: BodySkeleton?
var bodySkeletonAnchor = AnchorEntity()


struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true) // Access the camera
        
        // Load the "Box" scene from the "Experience" Reality File
        // let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        // arView.scene.anchors.append(boxAnchor)
        arView.setupForBodyTracking()
        arView.scene.addAnchor(bodySkeletonAnchor)
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

extension ARView: ARSessionDelegate {
    func setupForBodyTracking() {
        let config = ARBodyTrackingConfiguration()
        self.session.run(config)
        self.session.delegate = self
    }
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Character 
        
        // Skeleton Nodes
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                if let skeleton = bodySkeleton {
                    // BodySkeleton exists, update pose
                    skeleton.update(with: bodyAnchor)
                } else {
                    // See body for the first time, initialize skeleton
                    let skeleton = BodySkeleton(for: bodyAnchor)
                    bodySkeleton = skeleton
                    bodySkeletonAnchor.addChild(skeleton)
                    
                }
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
