//
//  GameScene.swift
//  FightTheGoodFIght
//
//  Created by Otis Young on 3/20/25.
//


import SpriteKit
import GameplayKit

// MARK: - Physics Categories
struct PhysicsCategory {
   static let None: UInt32 = 0
   static let Paddle: UInt32 = 0b1        // 1
   static let Bomb: UInt32 = 0b10         // 2
   static let Explosion: UInt32 = 0b100   // 4
}

class GameScene: SKScene, SKPhysicsContactDelegate {
   
   // MARK: - Properties
   var paddle: SKSpriteNode!
   var bombs: [SKSpriteNode] = []
   var scoreLabel: SKLabelNode!
   var score = 0
   var lifeLabel: SKLabelNode!
   var lives = 3
   var explosionTextures: [SKTexture] = []
   var bombTimer: Timer?
   var bombCount = 1
   var difficultyIncreaseTime: TimeInterval = 15
   var bossGuy: SKSpriteNode!
   var bossMoveAction: SKAction!
   var bossFakeOutAction: SKAction!
   var bombDropInterval: TimeInterval = 1.5
   var screenWidth: CGFloat!
   var safeAreaWidth: CGFloat!
   
   // MARK: - UI Elements
   var readyAgainButton: SKSpriteNode!
   var pauseButton: SKSpriteNode!
   
   // MARK: - Scene Setup
   override func didMove(to view: SKView) {
       // Get the safe area width to ensure the Boss stays within bounds
       let safeArea = view.safeAreaInsets
       screenWidth = frame.width
       safeAreaWidth = screenWidth - safeArea.left - safeArea.right
       
       // Set up the background
       let backdrop = SKSpriteNode(imageNamed: "BackDrop")
       backdrop.position = CGPoint(x: frame.midX, y: frame.midY)
       backdrop.zPosition = -1
       backdrop.size = CGSize(width: screenWidth, height: frame.height)
       addChild(backdrop)
       
       // Set up paddle (Catcher asset)
       paddle = SKSpriteNode(imageNamed: "Catcher")
       paddle.size = CGSize(width: 100, height: 20)
       paddle.position = CGPoint(x: frame.midX, y: 50)
       paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
       paddle.physicsBody?.isDynamic = false
       paddle.physicsBody?.categoryBitMask = PhysicsCategory.Paddle
       paddle.physicsBody?.contactTestBitMask = PhysicsCategory.Bomb
       paddle.physicsBody?.collisionBitMask = 0
       addChild(paddle)
       
       // Set up score label
       scoreLabel = SKLabelNode(text: "Score: 0")
       scoreLabel.fontSize = 32
       scoreLabel.fontColor = .black
       scoreLabel.position = CGPoint(x: frame.maxX - 100, y: frame.height - 40)
       addChild(scoreLabel)
       
       // Set up life label
       lifeLabel = SKLabelNode(text: "Lives: \(lives)")
       lifeLabel.fontSize = 32
       lifeLabel.fontColor = .black
       lifeLabel.position = CGPoint(x: frame.maxX - 100, y: frame.height - 80)
       addChild(lifeLabel)
       
       // Load explosion assets
       loadExplosionTextures()
       
       // Start bomb timer
       bombTimer = Timer.scheduledTimer(timeInterval: bombDropInterval, target: self, selector: #selector(dropBomb), userInfo: nil, repeats: true)
       
       // Set up gravity and physics world
       physicsWorld.gravity = CGVector(dx: 0, dy: -1)
       physicsWorld.contactDelegate = self
       
       // Create and set BossGuy
       bossGuy = SKSpriteNode(imageNamed: "BossGuy")
       bossGuy.size = CGSize(width: 100, height: 100)
       bossGuy.position = CGPoint(x: frame.midX, y: frame.height - 150)
       addChild(bossGuy)
       
       // Boss horizontal movement action
       let moveLeft = SKAction.moveBy(x: -safeAreaWidth / 2, y: 0, duration: 4.0)
       let moveRight = SKAction.moveBy(x: safeAreaWidth / 2, y: 0, duration: 4.0)
       let stayInPlace = SKAction.wait(forDuration: 1.0)
       let randomMoveAction = SKAction.sequence([moveLeft, stayInPlace, moveRight, stayInPlace])
       bossMoveAction = SKAction.repeatForever(randomMoveAction)
       
       // Make the Boss move horizontally
       bossGuy.run(SKAction.repeatForever(bossMoveAction))
       
       // Pause Button Setup
       pauseButton = SKSpriteNode(color: .red, size: CGSize(width: 80, height: 40))
       pauseButton.position = CGPoint(x: frame.maxX - 70, y: frame.height - 120) // Below the score
       pauseButton.name = "pauseButton"
       
       let pauseLabel = SKLabelNode(text: "Pause")
       pauseLabel.fontSize = 24
       pauseLabel.fontColor = .black
       pauseLabel.position = CGPoint(x: 0, y: 0)
       pauseButton.addChild(pauseLabel)
       
       addChild(pauseButton)
       
       // Ready Again Button (Initially Hidden)
       readyAgainButton = SKSpriteNode(color: .blue, size: CGSize(width: 200, height: 60))
       readyAgainButton.position = CGPoint(x: frame.midX, y: frame.midY)
       readyAgainButton.name = "readyAgainButton"
       let readyLabel = SKLabelNode(text: "Ready Again?")
       readyLabel.fontSize = 32
       readyLabel.fontColor = .white
       readyLabel.position = CGPoint(x: 0, y: 0)
       readyAgainButton.addChild(readyLabel)
       readyAgainButton.isHidden = true
       addChild(readyAgainButton)
   }
   
   // MARK: - Load Explosion Textures
   func loadExplosionTextures() {
       let explosion1 = SKTexture(imageNamed: "Explosion1")
       let explosion2 = SKTexture(imageNamed: "Explosion2")
       let explosion3 = SKTexture(imageNamed: "Explosion3")
       explosionTextures = [explosion1, explosion2, explosion3]
   }
   
   // MARK: - Drop Bombs
   @objc func dropBomb() {
       // Drop bombs directly under the BossGuy's position
       let bombsToDrop = min(3, bombCount)
       
       for _ in 0..<bombsToDrop {
           let newBomb = SKSpriteNode(imageNamed: "Record")
           newBomb.size = CGSize(width: 70, height: 70) // Set bomb size to 70x70
           newBomb.position = CGPoint(x: bossGuy.position.x, y: bossGuy.position.y - 50) // Directly under the BossGuy
           addChild(newBomb)
           bombs.append(newBomb)
           
           // Apply gravity to the bomb
           newBomb.physicsBody = SKPhysicsBody(rectangleOf: newBomb.size)
           newBomb.physicsBody?.affectedByGravity = true
           newBomb.physicsBody?.categoryBitMask = PhysicsCategory.Bomb
           newBomb.physicsBody?.contactTestBitMask = PhysicsCategory.Paddle
           newBomb.physicsBody?.collisionBitMask = PhysicsCategory.None
       }
       
       // Increase bomb drop rate after each wave (increase difficulty)
       bombCount += 1
       
       // Gradually reduce the bomb drop interval to increase difficulty
       if bombDropInterval > 0.5 {
           bombDropInterval -= 0.05 // Slightly increase the bomb drop rate
           bombTimer?.invalidate()
           bombTimer = Timer.scheduledTimer(timeInterval: bombDropInterval, target: self, selector: #selector(dropBomb), userInfo: nil, repeats: true)
       }
   }
   
   // MARK: - Handle Touches (Pause Button, Ready Again Button, and Paddle)
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       guard let touch = touches.first else { return }
       let touchLocation = touch.location(in: self)
       
       // Pause Button
       if pauseButton.contains(touchLocation) {
           isPaused = !isPaused
           if isPaused {
               // Stop BossGuy movement when paused
               bossGuy.removeAction(forKey: "bossMoveAction")
           } else {
               // Resume BossGuy movement when unpaused
               bossGuy.run(bossMoveAction, withKey: "bossMoveAction")
           }
           return
       }
       
       // Ready Again Button
       if readyAgainButton.contains(touchLocation) {
           resetGame()
       }
       
       // Prevent Paddle Movement if Game is Paused
       if isPaused {
           return
       }
       
       // Move the paddle (Catcher)
       let location = touch.location(in: self)
       paddle.position.x = location.x
   }
   
   // MARK: - Physics Contact Handling
   func didBegin(_ contact: SKPhysicsContact) {
       if contact.bodyA.categoryBitMask == PhysicsCategory.Paddle && contact.bodyB.categoryBitMask == PhysicsCategory.Bomb {
           // Bomb caught
           score += 10
           scoreLabel.text = "Score: \(score)"
           contact.bodyB.node?.removeFromParent()
           bombs.removeAll { $0 == contact.bodyB.node as? SKSpriteNode }
       } else if contact.bodyB.categoryBitMask == PhysicsCategory.Paddle && contact.bodyA.categoryBitMask == PhysicsCategory.Bomb {
           // Bomb caught
           score += 10
           scoreLabel.text = "Score: \(score)"
           contact.bodyA.node?.removeFromParent()
           bombs.removeAll { $0 == contact.bodyA.node as? SKSpriteNode }
       }
   }
   
   func didEnd(_ contact: SKPhysicsContact) {
       if contact.bodyA.categoryBitMask == PhysicsCategory.Bomb && contact.bodyB.categoryBitMask == PhysicsCategory.None {
           // Bomb missed, trigger explosion and lose life
           triggerExplosion(for: contact.bodyA.node!)
           lives -= 1
           lifeLabel.text = "Lives: \(lives)"
           
           // Check if the game is over
           if lives <= 0 {
               gameOver()
           }
       } else if contact.bodyB.categoryBitMask == PhysicsCategory.Bomb && contact.bodyA.categoryBitMask == PhysicsCategory.None {
           // Bomb missed, trigger explosion and lose life
           triggerExplosion(for: contact.bodyB.node!)
           lives -= 1
           lifeLabel.text = "Lives: \(lives)"
           
           // Check if the game is over
           if lives <= 0 {
               gameOver()
           }
       }
   }
   
   func triggerExplosion(for node: SKNode) {
       // Create explosion effect
       let explosion = SKSpriteNode(texture: explosionTextures.randomElement())
       explosion.position = node.position
       addChild(explosion)
       
       // Animate the explosion and remove it after a short time
       let fadeOut = SKAction.fadeOut(withDuration: 0.5)
       let remove = SKAction.removeFromParent()
       explosion.run(SKAction.sequence([fadeOut, remove]))
       
       // Remove the bomb from the scene
       node.removeFromParent()
   }
   
   // MARK: - Game Over Logic
   func gameOver() {
       // Pause the game
       isPaused = true
       
       // Show "Ready Again?" button
       readyAgainButton.isHidden = false
   }
   
   // MARK: - Reset Game Logic
   func resetGame() {
       // Reset score, lives, and other properties
       score = 0
       lives = 3
       scoreLabel.text = "Score: \(score)"
       lifeLabel.text = "Lives: \(lives)"
       
       // Hide Ready Again button
       readyAgainButton.isHidden = true
       
       // Reset paddle position
       paddle.position = CGPoint(x: frame.midX, y: 50)
       
       // Remove all bombs
       for bomb in bombs {
           bomb.removeFromParent()
       }
       bombs.removeAll()
       
       // Reset BossGuy position and movement
       bossGuy.position = CGPoint(x: frame.midX, y: frame.height - 150)
       bossGuy.run(SKAction.repeatForever(bossMoveAction))
       
       // Resume game
       isPaused = false
   }
}
