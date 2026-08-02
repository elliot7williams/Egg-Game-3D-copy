//
//  ContentView.swift
//  Egg Game 3D
//
//  Created by Elliot Williams on 2025-06-22.
//

import SwiftUI
import SceneKit
import CoreMotion
import AVFoundation

struct EggCatcherGame: View {
    @State private var score = 0
    @State private var eggsMissed = 0
    @State private var gameActive = true
    
    var body: some View {
        ZStack {
            // Game Scene
            GameSceneView(score: $score, eggsMissed: $eggsMissed, gameActive: $gameActive)
                .edgesIgnoringSafeArea(.all)
            
            // Game UI
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Score: \(score)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                        
                        Text("Missed: \(eggsMissed)/10")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(eggsMissed < 8 ? .yellow : .red)
                            .shadow(color: .black, radius: 2)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        gameActive.toggle()
                    }) {
                        Image(systemName: gameActive ? "pause.circle" : "play.circle")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                if !gameActive {
                    Text("PAUSED")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 5)
                }
                
                if eggsMissed >= 10 {
                    VStack {
                        Text("GAME OVER")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.red)
                            .shadow(color: .black, radius: 5)
                        
                        Text("Final Score: \(score)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        Button(action: {
                            score = 0
                            eggsMissed = 0
                            gameActive = true
                        }) {
                            Text("Play Again")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
                
                Text("Tilt device to move basket")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 30)
            }
        }
        .background(Color.black)
    }
}

struct GameSceneView: UIViewRepresentable {
    @Binding var score: Int
    @Binding var eggsMissed: Int
    @Binding var gameActive: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = createGameScene()
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)
        scnView.delegate = context.coordinator
        scnView.isPlaying = true
        
        // Add swipe gesture for camera control
        let swipeGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe(_:)))
        scnView.addGestureRecognizer(swipeGesture)
        
        return scnView
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        context.coordinator.setGameActive(gameActive)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, score: $score, eggsMissed: $eggsMissed, gameActive: $gameActive)
    }
    
    func createGameScene() -> SCNScene {
        let scene = SCNScene()
        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
cameraNode.position = SCNVector3(0, 7, 15)
        scene.rootNode.addChildNode(cameraNode)
        
        // Lighting
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor(white: 0.3, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        
        let directionalLight = SCNLight()
        directionalLight.type = .directional
directionalLight.intensity = 1500
        directionalLight.castsShadow = true
        directionalLight.shadowRadius = 5
        directionalLight.shadowColor = UIColor.black.withAlphaComponent(0.5)
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.position = SCNVector3(0, 10, 0)
        directionalLightNode.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0)
        scene.rootNode.addChildNode(directionalLightNode)
        
        // Ground
        let groundGeometry = SCNFloor()
        groundGeometry.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.5)
        groundGeometry.firstMaterial?.specular.contents = UIColor.white
        let groundNode = SCNNode(geometry: groundGeometry)
        groundNode.position = SCNVector3(0, -1, 0)
        scene.rootNode.addChildNode(groundNode)
        
// Skybox with fallback
        if let skyImages = ["sky_cloud_1.png", "sky_cloud_2.png", "sky_cloud_3.png", "sky_cloud_4.png", "sky_cloud_5.png", "sky_cloud_6.png"].compactMap({ UIImage(named: $0) }), !skyImages.isEmpty {
            scene.background.contents = skyImages
        } else {
            // Fallback to gradient background
            scene.background.contents = UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 1.0)
        }
        
        // Basket
        let basket = createBasket()
        basket.position = SCNVector3(0, 0.5, 0)
        scene.rootNode.addChildNode(basket)
        
        // Trees
        for i in -1...1 {
            for j in -1...1 {
                if i != 0 || j != 0 {
                    let tree = createTree()
                    tree.position = SCNVector3(Float(i) * 8, 0, Float(j) * 8)
                    scene.rootNode.addChildNode(tree)
                }
            }
        }
        
        // Rabbits
        for _ in 0..<3 {
            let rabbit = createRabbit()
            rabbit.position = SCNVector3(
                Float.random(in: -5...5),
                0,
                Float.random(in: -5...5)
            )
            scene.rootNode.addChildNode(rabbit)
        }
        
        return scene
    }
    
    func createBasket() -> SCNNode {
        let basketNode = SCNNode()
        
        // Basket base
        let basketBase = SCNCylinder(radius: 1, height: 0.2)
        basketBase.firstMaterial?.diffuse.contents = UIColor.brown
        let baseNode = SCNNode(geometry: basketBase)
        baseNode.position.y = 0.1
        basketNode.addChildNode(baseNode)
        
        // Basket sides
        for i in 0..<8 {
            let angle = Float(i) * (Float.pi / 4)
            let stick = SCNBox(width: 0.1, height: 1, length: 0.1, chamferRadius: 0.05)
            stick.firstMaterial?.diffuse.contents = UIColor.brown
            let stickNode = SCNNode(geometry: stick)
            stickNode.position = SCNVector3(sin(angle), 0.5, cos(angle))
            basketNode.addChildNode(stickNode)
        }
        
        // Basket handle
        let handle = SCNTorus(ringRadius: 0.8, pipeRadius: 0.05)
        handle.firstMaterial?.diffuse.contents = UIColor.brown
        let handleNode = SCNNode(geometry: handle)
        handleNode.position.y = 1
        handleNode.eulerAngles.x = Float.pi / 2
        basketNode.addChildNode(handleNode)
        
        // Physics body
        let sphere = SCNSphere(radius: 1.0)
        let physicsShape = SCNPhysicsShape(geometry: sphere, options: nil)
        let physicsBody = SCNPhysicsBody(type: .kinematic, shape: physicsShape)
        basketNode.physicsBody = physicsBody
        basketNode.name = "basket"
        
        return basketNode
    }
    
    func createTree() -> SCNNode {
        let treeNode = SCNNode()
        
        // Trunk
        let trunk = SCNCylinder(radius: 0.3, height: 2)
        trunk.firstMaterial?.diffuse.contents = UIColor.brown
        let trunkNode = SCNNode(geometry: trunk)
        trunkNode.position.y = 1
        treeNode.addChildNode(trunkNode)
        
        // Leaves
        let leaves = SCNSphere(radius: 1.2)
        leaves.firstMaterial?.diffuse.contents = UIColor.green
        let leavesNode = SCNNode(geometry: leaves)
        leavesNode.position.y = 3
        treeNode.addChildNode(leavesNode)
        
        return treeNode
    }
    
    func createRabbit() -> SCNNode {
        let rabbitNode = SCNNode()
        
        // Body
        let body = SCNCylinder(radius: 0.3, height: 0.5)
        body.firstMaterial?.diffuse.contents = UIColor.white
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position.y = 0.25
        rabbitNode.addChildNode(bodyNode)
        
        // Head
        let head = SCNSphere(radius: 0.25)
        head.firstMaterial?.diffuse.contents = UIColor.white
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 0.25, 0.4)
        rabbitNode.addChildNode(headNode)
        
        // Ears
        for i in [-1, 1] {
            let ear = SCNCylinder(radius: 0.05, height: 0.6)
            ear.firstMaterial?.diffuse.contents = UIColor.systemPink
            let earNode = SCNNode(geometry: ear)
            earNode.position = SCNVector3(Float(i) * 0.15, 0.5, 0)
            earNode.eulerAngles.z = Float(i) * 0.2
            rabbitNode.addChildNode(earNode)
        }
        
        // Eyes
        for i in [-1, 1] {
            let eye = SCNSphere(radius: 0.05)
            eye.firstMaterial?.diffuse.contents = UIColor.black
            let eyeNode = SCNNode(geometry: eye)
            eyeNode.position = SCNVector3(Float(i) * 0.1, 0.25, 0.55)
            rabbitNode.addChildNode(eyeNode)
        }
        
        // Physics body
        let physicsShape = SCNPhysicsShape(geometry: SCNSphere(radius: 0.4), options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        physicsBody.isAffectedByGravity = false
        physicsBody.categoryBitMask = 4
        physicsBody.collisionBitMask = 0
        rabbitNode.physicsBody = physicsBody
        rabbitNode.name = "rabbit"
        
        return rabbitNode
    }
    
var lastCatchTime: TimeInterval? // Initializing last catch time

    class Coordinator: NSObject, SCNSceneRendererDelegate {
        var parent: GameSceneView
        var score: Binding<Int>
        var eggsMissed: Binding<Int>
        var gameActive: Binding<Bool>
        var lastUpdateTime: TimeInterval?
        var basketNode: SCNNode?
        var motionManager: CMMotionManager?
        var cameraAngle: Float = 0
        
        init(parent: GameSceneView, score: Binding<Int>, eggsMissed: Binding<Int>, gameActive: Binding<Bool>) {
            self.parent = parent
            self.score = score
            self.eggsMissed = eggsMissed
            self.gameActive = gameActive
            super.init()
            setupMotionManager()
        }
        
        func setGameActive(_ active: Bool) {
            // Update the binding's wrapped value
            gameActive.wrappedValue = active
        }
        
        func setupMotionManager() {
            motionManager = CMMotionManager()
            if motionManager?.isDeviceMotionAvailable == true {
                motionManager?.deviceMotionUpdateInterval = 1/60
                motionManager?.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                    guard let self = self, let motion = motion else { return }
                    
                    let rotationRateX = Float(motion.rotationRate.x) * 0.1
                    let rotationRateZ = Float(motion.rotationRate.z) * 0.1
                    
                    if self.gameActive.wrappedValue {
                        self.basketNode?.position.x -= rotationRateZ
                        self.basketNode?.position.z -= rotationRateX
                        
                        self.basketNode?.position.x = max(-8, min(8, self.basketNode?.position.x ?? 0))
                        self.basketNode?.position.z = max(-8, min(8, self.basketNode?.position.z ?? 0))
                    }
                }
            }
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard let scene = renderer.scene else { return }
            
            if basketNode == nil {
                basketNode = scene.rootNode.childNode(withName: "basket", recursively: true)
            }
            
            let deltaTime: TimeInterval
            if let lastUpdateTime = lastUpdateTime {
                deltaTime = time - lastUpdateTime
            } else {
                deltaTime = 0
            }
            lastUpdateTime = time
            
            guard gameActive.wrappedValue, eggsMissed.wrappedValue < 10 else { return }
            
let dropRate = max(5, 10 - score.wrappedValue / 10)
            if Int.random(in: 0...100) < dropRate {
                spawnEgg(in: scene)
            }
            
            for node in scene.rootNode.childNodes {
                if node.name == "egg" {
                    node.eulerAngles.x += Float(deltaTime) * 2
                    node.eulerAngles.z += Float(deltaTime) * 1.5
                    
                    if node.position.y < 0 {
                        node.removeFromParentNode()
                        eggsMissed.wrappedValue += 1
                        if eggsMissed.wrappedValue >= 10 {
                            playSoundEffect(name: "game_over")
                        }
                    }
                }
                
                if node.name == "rabbit" {
                    node.position.x += Float.random(in: -0.01...0.01)
                    node.position.z += Float.random(in: -0.01...0.01)
                    
                    node.position.x = max(-8, min(8, node.position.x))
                    node.position.z = max(-8, min(8, node.position.z))
                    
                    node.eulerAngles.y += Float(deltaTime) * 0.5
                }
            }
            
            if let camera = scene.rootNode.childNodes.first(where: { $0.camera != nil }) {
                let basketPos = basketNode?.position ?? SCNVector3(0, 0.5, 0)
                camera.position = SCNVector3(
                    basketPos.x + 8 * sin(cameraAngle),
                    5,
                    basketPos.z + 8 * cos(cameraAngle)
                )
                camera.look(at: basketPos)
            }
        }
        
        func spawnEgg(in scene: SCNScene) {
            let eggGeometry = SCNSphere(radius: 0.2)
            eggGeometry.firstMaterial?.diffuse.contents = UIColor.white
            eggGeometry.firstMaterial?.specular.contents = UIColor.white
            eggGeometry.firstMaterial?.shininess = 0.5
            
            let eggNode = SCNNode(geometry: eggGeometry)
            eggNode.position = SCNVector3(
                Float.random(in: -8...8),
                15,
                Float.random(in: -8...8)
            )
            eggNode.name = "egg"
            
            let physicsShape = SCNPhysicsShape(geometry: SCNSphere(radius: 0.2), options: nil)
            let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
            physicsBody.isAffectedByGravity = true
            physicsBody.categoryBitMask = 1
            physicsBody.contactTestBitMask = 2
            eggNode.physicsBody = physicsBody
            
            scene.rootNode.addChildNode(eggNode)
        }
        
        @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
            guard gesture.state == .changed else { return }
            
            let translation = gesture.translation(in: gesture.view)
            cameraAngle += Float(translation.x) * 0.01
            gesture.setTranslation(.zero, in: gesture.view)
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
            guard let scene = renderer.scene else { return }
            scene.physicsWorld.contactDelegate = self
        }
    }
}

extension GameSceneView.Coordinator: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if (contact.nodeA.name == "egg" && contact.nodeB.name == "basket") ||
           (contact.nodeA.name == "basket" && contact.nodeB.name == "egg") {
            
            let eggNode = contact.nodeA.name == "egg" ? contact.nodeA : contact.nodeB
            eggNode.removeFromParentNode()
            
            // Base score increment
            score.wrappedValue += 1
            
            // Score multiplier for consecutive catches
            let currentTime = CACurrentMediaTime()
            if let lastCatch = parent.lastCatchTime, currentTime - lastCatch < 2.0 {
                score.wrappedValue += 2 // Bonus points for quick consecutive catches
            }
            parent.lastCatchTime = currentTime
            
            playSoundEffect(name: "collect")
        }
    }
}

func playSoundEffect(name: String) {
    guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }

    var soundEffect: AVAudioPlayer?
    do {
        soundEffect = try AVAudioPlayer(contentsOf: url)
        soundEffect?.play()
    } catch {
        print("Failed to play sound: \(error)")
    }
}

struct ContentView: View {
    var body: some View {
        EggCatcherGame()
    }
}
