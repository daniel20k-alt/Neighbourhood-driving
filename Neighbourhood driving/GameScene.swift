//
//  GameScene.swift
//  Neighbourhood driving
//
//  Created by DDDD on 25/08/2020.
//  Copyright © 2020 MeerkatWorks. All rights reserved.
//

import SpriteKit

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case fuel = 8
    case hole = 16
    case finish = 32
}

class GameScene: SKScene {
    
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background")
            background.position = CGPoint(x: 512, y: 384)
            background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
            
        loadLevel()
        createPlayer()
        
        physicsWorld.gravity = .zero
        
    }
    
    func loadLevel() {
        guard let levelURL = Bundle.main.url(forResource: "level1", withExtension: "txt") else {
            fatalError("Could not find level1.txt in the app bundle.")
        }
        
        guard let levelString = try? String(contentsOf: levelURL) else {
            fatalError("Could not load level1.txt from the app bundle.")
        }
        
        let lines = levelString.components(separatedBy: "\n")
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                
                if letter == "x" {
                    //loading a wall/building
                    
                    let node = SKSpriteNode(imageNamed: "block")
                    node.position = position
                    node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                    node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
                    node.physicsBody?.isDynamic = false
                    
                    addChild(node)
                    
                } else if letter == "h" {
                    //loading the holes
                    
                    let randomizer = Int.random(in: 1...2)
                    let node = SKSpriteNode(imageNamed: "hole_\(randomizer)")
                    node.name = "hole"
                    
                    let angleRandomizer = Int.random (in: 1...360)
                    node.run(SKAction.repeat(SKAction.rotate(byAngle: CGFloat(angleRandomizer), duration: 0.1), count: 1))  //ensure different position for each hole
                    
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2.2) //ensure that the player will not fall when simply touching the cracks
                    node.physicsBody?.isDynamic = false
                   
                    node.physicsBody?.categoryBitMask = CollisionTypes.hole.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue //we are notified when player touches it
                    node.physicsBody?.collisionBitMask = 0 //does not bounce
                    
                     node.position = position
                    addChild(node)
                    
                } else if letter == "s" {
                    //loading star points
                    
                    let randomizer = Int.random(in: 1...2)
                    let node = SKSpriteNode(imageNamed: "star_\(randomizer)")
                    node.name = "star"
                    
                    node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1))) //ensure that the stars are moving
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    
                    node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    
                    node.position = position
                    addChild(node)
                    
                } else if letter == "f" {
                    //loading fuel
                    
                    let node = SKSpriteNode(imageNamed: "fuel_1")
                    node.name = "fuel"
                    
                    node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                    node.physicsBody?.isDynamic = false
                    
                    node.physicsBody?.categoryBitMask = CollisionTypes.fuel.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    
                    node.position = position
                    addChild(node)
                    
                    
                } else if letter == "z" {
                    //finishing level
                    //TODO: get a finish line image or something similar
                    
                    let node = SKSpriteNode(imageNamed: "finish_1")
                    node.name = "finish"

                    node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                    node.physicsBody?.isDynamic = false
                    
                    node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    
                    node.position = position
                    addChild(node)
                    
                } else if letter == " " {
                //these are the empty spaces which do nothing
                
                } else {
                    fatalError("Uknown level letter: \(letter)")
                }
            }
        }
    }
    
    func createPlayer() {
        player = SKSpriteNode(imageNamed: "moto_1") //"moto_test" smaller
        player.position = CGPoint(x: 96, y: 672) //initial position for level 1 only
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2.2)
        player.physicsBody?.allowsRotation = false
      
        /////////////////////////////////////////////////////////////////////////////////////
        //TODO: make the moto rotate in the direction it is currently heading
//        player.physicsBody?.allowsRotation = true
//
//        let angleRandomizer = Int.random (in: 1...360) //adjust randomizer depending on the method of tilting the display
//        player.run(SKAction.repeat(SKAction.rotate(byAngle: CGFloat(angleRandomizer), duration: 1), count: 1))  //adjust to have th necessary angle for each rotation
//        player.physicsBody?.isDynamic = false
        //////////////////
        
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask =  CollisionTypes.fuel.rawValue | CollisionTypes.hole.rawValue | CollisionTypes.finish.rawValue | CollisionTypes.star.rawValue
        
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        
        addChild(player)
    }
    
    //Allowing the player to move the motorcycle with touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let lastTouchPosition = lastTouchPosition {
            let diff = CGPoint(x: lastTouchPosition.x - player.position.x, y: lastTouchPosition.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
    }
}
