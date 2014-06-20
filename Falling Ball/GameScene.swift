//
//  GameScene.swift
//  Flappy Bird
//
//  Created by Connor Christie on 6/6/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate
{
    var bird: SKShapeNode = SKShapeNode(circleOfRadius: 15)
    var overlay: SKSpriteNode = SKSpriteNode()
    
    var ground1: SKSpriteNode = SKSpriteNode()
    var ground2: SKSpriteNode = SKSpriteNode()
    
    var background1: SKSpriteNode = SKSpriteNode()
    var background2: SKSpriteNode = SKSpriteNode()
    
    var scoreLabel = SKLabelNode(fontNamed: "System-Bold")
    
    var mainPipe: Pipe = Pipe()
    var pipes: Pipe[] = []
    
    var score: Int = 0
    var space: Float = 110
    
    var prevNum: Float = 0
    var prevOffset: Float = 0
    
    var maxRange: Float = 200
    var minRange: Float = -200
    
    var maxOffset: Float = 300
    
    var pipeCategory: UInt32 = 1
    var birdCategory: UInt32 = 2
    
    var isMoving: Bool = false
    var groundMoving: Bool = true
    
    var movingMult: Float = 200
    var enableHits: Bool = true
    
    var prevTime: CFTimeInterval = 0
    
    var motion: CMMotionManager = CMMotionManager()
    var queue:  NSOperationQueue = NSOperationQueue()
    
    var acceleration: CMAcceleration = CMAcceleration(x: 0, y: 0, z: 0)
    
    override func didMoveToView(view: SKView)
    {
        background1 = SKSpriteNode(imageNamed: "Background")
        background2 = SKSpriteNode(imageNamed: "Background")
        
        background1.zPosition = -10
        background2.zPosition = -10
        
        background1.position.x = view.bounds.size.width * 0.5
        background2.position.x = view.bounds.size.width * 1.5
        
        background1.position.y = view.bounds.size.height * 0.5
        background2.position.y = view.bounds.size.height * 0.5
        
        background1.texture.filteringMode = SKTextureFilteringMode.Nearest
        background2.texture.filteringMode = SKTextureFilteringMode.Nearest
        
        ground1 = SKSpriteNode(imageNamed: "Ground")
        ground2 = SKSpriteNode(imageNamed: "Ground")
        
        ground1.name = "Ground1"
        ground2.name = "Ground2"
        
        ground1.texture.filteringMode = SKTextureFilteringMode.Nearest
        ground2.texture.filteringMode = SKTextureFilteringMode.Nearest
        
        ground1.size.width = view.bounds.size.width + 2
        ground2.size.width = view.bounds.size.width + 2
        
        ground1.position.x = view.bounds.size.width * 0.5
        ground2.position.x = view.bounds.size.width * 1.5
        
        ground1.position.y = ground1.size.height * 0.4
        ground2.position.y = ground2.size.height * 0.4
        
        ground1.zPosition = 10
        ground2.zPosition = 10
        
        ground1.physicsBody = SKPhysicsBody(rectangleOfSize: ground1.size)
        ground2.physicsBody = SKPhysicsBody(rectangleOfSize: ground2.size)
        
        ground1.physicsBody.dynamic = false
        ground2.physicsBody.dynamic = false
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: 15)
        bird.physicsBody.dynamic = false
        
        bird.zPosition = 9
        bird.lineWidth = 0
        
        bird.fillColor = UIColor.blackColor()
        bird.position  = CGPoint(x: self.view.bounds.size.width / 2 - 10, y: view.bounds.height - 100)
        
        scoreLabel.position.x = 13
        scoreLabel.position.y = view.bounds.height - 50
        
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        
        scoreLabel.hidden = true
        scoreLabel.zPosition = 12
        
        overlay = SKSpriteNode(color: UIColor.grayColor(), size: CGSize(width: self.view.bounds.width, height: self.view.bounds.height))
        
        overlay.alpha = 0.7
        overlay.zPosition = 11
        
        overlay.position.x += overlay.size.width / 2
        overlay.position.y += overlay.size.height / 2
        
        mainPipe = Pipe(color: UIColor.blackColor(), size: CGSize(width: 480, height: view.bounds.size.height / 6))
        
        motion.accelerometerUpdateInterval  = 1.0 / 10.0
        
        if (motion.accelerometerAvailable)
        {
            motion.startAccelerometerUpdatesToQueue(queue, withHandler: {
                deviceManager, error in
                
                self.acceleration = deviceManager.acceleration
            })
        }
        
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVectorMake(0, -5.0)
        
        //self.addChild(background1)
        //self.addChild(background2)
        
        //self.addChild(ground1)
        //self.addChild(ground2)
        
        self.addChild(bird)
        self.addChild(scoreLabel)
    }
    
    func spawnPipeRow(offs: Float)
    {
        let offset = offs - (space / 2)
        
        let pLef = mainPipe.copy() as Pipe
        let pRig = mainPipe.copy() as Pipe
        
        pLef.isLeft = true
        
        pLef.texture = SKTexture(imageNamed: "LeftPipe")
        pRig.texture = SKTexture(imageNamed: "RightPipe")
        
        pLef.texture.filteringMode = SKTextureFilteringMode.Nearest
        pRig.texture.filteringMode = SKTextureFilteringMode.Nearest
        
        let yy: Float = -pLef.size.height
        
        self.setPositionRelativeBot(pLef, x: offset, y: yy)
        self.setPositionRelativeTop(pRig, x: offset + space, y: yy)
        
        pLef.physicsBody = SKPhysicsBody(rectangleOfSize: pLef.size)
        pRig.physicsBody = SKPhysicsBody(rectangleOfSize: pRig.size)
        
        pLef.physicsBody.dynamic = false
        pRig.physicsBody.dynamic = false
        
        if (enableHits)
        {
            pLef.physicsBody.contactTestBitMask = birdCategory
            pRig.physicsBody.contactTestBitMask = birdCategory
            
            pLef.physicsBody.collisionBitMask   = birdCategory
            pRig.physicsBody.collisionBitMask   = birdCategory
        }
        
        pipes.append(pLef)
        pipes.append(pRig)
        
        self.addChild(pLef)
        self.addChild(pRig)
    }
    
    func randomOffset() -> Float
    {
        var max = maxRange - prevNum
        var min = minRange - prevNum
        
        var rNum:  Float = Float(arc4random() % 61) + 30
        var rNum1: Float = Float(arc4random() % 31) + 1
        
        if (rNum1 % 2 == 0)
        {
            var tempNum = prevNum + rNum
            
            if (tempNum > maxRange)
            {
                tempNum = maxRange - rNum
            }
            
            rNum = tempNum
        } else
        {
            var tempNum = prevNum - rNum
            
            if (tempNum < minRange)
            {
                tempNum = minRange + rNum
            }
            
            rNum = tempNum
        }
        
        prevNum = rNum
        
        return rNum
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent)
    {
        /* Called when a touch begins */
        
        if (!bird.physicsBody.dynamic)
        {
            //First touch
            
            self.spawnPipeRow(0)
            
            bird.physicsBody.dynamic = true
            
            if (enableHits)
            {
                bird.physicsBody.contactTestBitMask = pipeCategory
                bird.physicsBody.collisionBitMask   = pipeCategory
            }
            
            isMoving = true
            groundMoving = true
            
            scoreLabel.hidden = false
        } else
        {
            overlay.removeFromParent()
            
            for pi in pipes
            {
                pi.removeFromParent()
            }
            
            pipes.removeAll(keepCapacity: false)
            
            score = 0
            
            bird.physicsBody.dynamic = false
            bird.position = CGPoint(x: self.view.bounds.size.width / 2 - 10, y: view.bounds.height - 100)
            
            scoreLabel.hidden = true
            
            groundMoving = true
        }
    }
    
    override func update(currentTime: CFTimeInterval)
    {
        /* Called before each frame is rendered */
        
        if (groundMoving)
        {
            var movingSpeed: Float = 0
            
            if (prevTime != 0)
            {
                movingSpeed = Float(currentTime - prevTime) * movingMult
            }
            
            prevTime = currentTime
            
            /*
            if (ground1.position.x <= -self.view.bounds.size.width / 2)
            {
            ground1.position.x = self.view.bounds.size.width * 1.5 - 2
            }
            
            if (ground2.position.x <= -self.view.bounds.size.width / 2)
            {
            ground2.position.x = self.view.bounds.size.width * 1.5 - 2
            }
            
            if (background1.position.x <= -self.view.bounds.size.width / 2)
            {
            background1.position.x = self.view.bounds.size.width * 1.5 - 2
            }
            
            if (background2.position.x <= -self.view.bounds.size.width / 2)
            {
            background2.position.x = self.view.bounds.size.width * 1.5 - 2
            }
            
            ground1.position.x -= movingSpeed
            ground2.position.x -= movingSpeed
            
            background1.position.x -= movingSpeed / 3
            background2.position.x -= movingSpeed / 3
            
            let distG: Float = ground1.position.x - ground2.position.x
            let distB: Float = background1.position.x - background2.position.x
            
            if (distG < 0)
            {
            ground1.position.x += -320 - distG
            } else
            {
            ground1.position.x += 320 - distG
            }
            
            if (distB < 0)
            {
            background1.position.x += -320 - distB
            } else
            {
            background1.position.x += 320 - distB
            }
            */
            
            if (isMoving)
            {
                var accelY = acceleration.y
                
                if (UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeLeft)
                {
                    accelY = -acceleration.y
                }
                
                bird.physicsBody.velocity = CGVectorMake(Float(accelY * 900), 0)
                
                for (var p = 0; p < pipes.count; p++)
                {
                    let pi = pipes[p]
                    
                    if (!pi.removed)
                    {
                        if (pi.position.y + (pi.size.height / 2) < self.view.bounds.size.height / 2
                            && pi.isLeft && !pi.pointAdded)
                        {
                            score++
                            
                            pi.pointAdded = true
                        }
                        
                        pi.position.y += movingSpeed
                        
                        if (p == pipes.count - 1)
                        {
                            if (pi.position.y > pi.size.height * 2.4)
                            {
                                self.spawnPipeRow(self.randomOffset())
                            }
                        }
                        
                        if (pi.position.y - (pi.size.height / 2) > self.view.bounds.height)
                        {
                            pi.removed = true
                            
                            pi.removeFromParent()
                        }
                    }
                }
                
                scoreLabel.text = "Score: \(score)"
            }
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact!)
    {
        if (isMoving)
        {
            isMoving = false
            groundMoving = false
        
            bird.physicsBody.velocity = CGVectorMake(0, 250)
        
            prevTime = 0
        
            for pi in pipes
            {
                pi.physicsBody = nil
            }
        
            self.addChild(overlay)
        } else
        {
            bird.physicsBody.velocity = CGVectorMake(0, 0)
        }
    }
    
    func clamp(num: Float, min: Float, max: Float) -> Float
    {
        if (num < min)
        {
            return min
        } else if (num > max)
        {
            return max
        }
        
        return num
    }
    
    func setPositionRelativeBot(node: SKSpriteNode, x: Float, y: Float)
    {
        let xx = Float(self.view.bounds.size.width / 2) - Float(node.size.width / 2) + x
        let yy = Float(node.size.height / 2) + y
        
        node.position.x = CGFloat(xx)
        node.position.y = CGFloat(yy)
    }
    
    func setPositionRelativeTop(node: SKSpriteNode, x: Float, y: Float)
    {
        let xx = Float(self.view.bounds.size.width / 2) + Float(node.size.width / 2) + x
        let yy = Float(node.size.height / 2) + y
        
        node.position.x = CGFloat(xx)
        node.position.y = CGFloat(yy)
    }
    
    class Pipe: SKSpriteNode
    {
        var isLeft: Bool = false
        
        var pointAdded: Bool = false
        
        var removed: Bool = false
    }
}