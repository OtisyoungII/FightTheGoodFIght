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
    var safeArea: UIEdgeInsets!
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
        
        
        
        // Pause Button Setup
        pauseButton = SKSpriteNode(imageNamed: "PauseButt")
        pauseButton.position = CGPoint(x: frame.maxX - 70, y: frame.height - 175) // Below the score part
        pauseButton.name = "PauseButt"
        pauseButton.size = CGSize(width: 100, height: 100) // Resize the pause button
        addChild(pauseButton)
        
        // Ready Again Button (Initially Hidden)
        readyAgainButton = SKSpriteNode(color: .blue, size: CGSize(width: 150, height: 50)) // Resize the button here
        readyAgainButton.position = CGPoint(x: frame.midX, y: frame.midY - 100) // Moved position to avoid score and lives
        readyAgainButton.name = "readyAgainButton"
        let readyLabel = SKLabelNode(text: "Ready Again?")
        readyLabel.fontSize = 24
        readyLabel.fontColor = .white
        readyLabel.position = CGPoint(x: 0, y: 0)
        readyAgainButton.addChild(readyLabel)
        readyAgainButton.isHidden = true
        addChild(readyAgainButton)
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
            // Bomb missed, lose life
            lives -= 1
            lifeLabel.text = "Lives: \(lives)"
            
            // Show explosion when bomb is missed
            let explosion = SKSpriteNode(texture: explosionTextures.randomElement())
            explosion.position = contact.bodyA.node!.position
            addChild(explosion)
            
            // Animate the explosion
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            explosion.run(SKAction.sequence([fadeOut, remove]))
            
            // Check if the game is over
            if lives <= 0 {
                gameOver()
            }
        }
    }
    
    
    // MARK: - Load Explosion Textures
    func loadExplosionTextures() {
        let explosion1 = SKTexture(imageNamed: "Explosion1")
        let explosion2 = SKTexture(imageNamed: "Explosion2")
        let explosion3 = SKTexture(imageNamed: "Explosion3")
        explosionTextures = [explosion1, explosion2, explosion3]
    }
    
    @objc func dropBomb() {
        // Drop bombs directly under the BossGuy's position
        let bombsToDrop = min(3, bombCount)
        
        for _ in 0..<bombsToDrop {
            let newBomb = SKSpriteNode(imageNamed: "Record")
            newBomb.size = CGSize(width: 70, height: 70) // Set bomb size to 70x70
            newBomb.position = CGPoint(x: bossGuy.position.x, y: bossGuy.position.y - 50) // perfectly under the BossGuy
            addChild(newBomb)
            bombs.append(newBomb)
            
            // Boss horizontal movement action with bounds checking
            let moveLeft = SKAction.moveBy(x: -frame.width / 2 + bossGuy.size.width / 2, y: 0, duration: 4.0)
            let moveRight = SKAction.moveBy(x: frame.width / 2 - bossGuy.size.width / 2, y: 0, duration: 4.0)
            let stayInPlace = SKAction.wait(forDuration: 1.0)
            
            let randomMoveAction = SKAction.sequence([moveLeft, stayInPlace, moveRight, stayInPlace])
            bossMoveAction = SKAction.repeatForever(randomMoveAction)
            
            // Correct the bounds check for screen edges
            let screenLeft = frame.minX + bossGuy.size.width / 2
            let screenRight = frame.maxX - bossGuy.size.width / 2
            
            // Check if the BossGuy is about to move off-screen and reverse direction
            if bossGuy.position.x - bossGuy.size.width / 2 <= screenLeft {
                // Reverse direction if BossGuy is about to move off the left screen boundary
                bossGuy.run(SKAction.sequence([moveRight, stayInPlace, moveLeft, stayInPlace]))
            } else if bossGuy.position.x + bossGuy.size.width / 2 >= screenRight {
                // Reverse direction if BossGuy is about to move off the right screen boundary
                bossGuy.run(SKAction.sequence([moveLeft, stayInPlace, moveRight, stayInPlace]))
            } else {
                // Regular horizontal movement
                bossGuy.run(SKAction.repeatForever(bossMoveAction))
            }
            
            // Increase difficulty over time
            run(SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.wait(forDuration: difficultyIncreaseTime),
                    SKAction.run { self.increaseDifficulty() }
                ])
            ))
            
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
    
        
        // MARK: - Trigger Explosion
        func triggerExplosion(at position: CGPoint) {
            // Create an explosion at the position of the bomb
            let explosion = SKSpriteNode(texture: explosionTextures[0])
            explosion.position = position
            explosion.zPosition = 10 // Ensure the explosion is above other elements (paddle, bombs)
            
            // Scale down the explosion (adjust the scale as needed)
            explosion.xScale = 0.5  // Scale to 50% of the original size
            explosion.yScale = 0.5  // Scale to 50% of the original size
            
            addChild(explosion)
            
            // Animation for explosion
            let explodeAction = SKAction.sequence([
                SKAction.animate(with: explosionTextures, timePerFrame: 0.1),
                SKAction.wait(forDuration: 0.2), // Allow slight delay before removal
                SKAction.removeFromParent()
            ])
            explosion.run(explodeAction)
            
            // Optionally trigger explosions for all bombs (if necessary, adjust this part)
            for bomb in bombs {
                let bombExplosion = SKSpriteNode(texture: explosionTextures[0])
                bombExplosion.position = bomb.position
                bombExplosion.zPosition = 10 // Ensure visibility above other elements
                
                // Scale the bomb explosion too (adjust the scale as needed)
                bombExplosion.xScale = 0.5
                bombExplosion.yScale = 0.5
                
                addChild(bombExplosion)
                
                let bombExplodeAction = SKAction.sequence([
                    SKAction.animate(with: explosionTextures, timePerFrame: 0.1),
                    SKAction.wait(forDuration: 0.2), // Slight delay before removal
                    SKAction.removeFromParent()
                ])
                bombExplosion.run(bombExplodeAction)
            }
        }
    }
    // MARK: - Increase Difficulty
    func increaseDifficulty() {
        difficultyIncreaseTime -= 1  // Shorten the interval between bomb drops (faster bombs)
        
        // Optionally, increase gravity or bomb drop speed, making the game harder
        physicsWorld.gravity = CGVector(dx: 0, dy: -1 - CGFloat(difficultyIncreaseTime / 10)) // Increase gravity
    }
    
    // MARK: - Handle Touches (Pause Button, Ready Again Button, and Paddle)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        // Pause Button
        if pauseButton.contains(touchLocation) {
            // Toggle the pause state
            isPaused = !isPaused
            
            // Change the pause button's image depending on the pause state
            if isPaused {
                // Set to pressed state when game is paused
                pauseButton.texture = SKTexture(imageNamed: "PressedPause")
                
                // Stop BossGuy movement when paused
                bossGuy.removeAction(forKey: "bossMoveAction")
            } else {
                // Set to unpressed state when game is unpaused
                pauseButton.texture = SKTexture(imageNamed: "PauseButt")
                
                // Resume BossGuy movement when unpaused
                bossGuy.run(bossMoveAction, withKey: "bossMoveAction")
            }
            
            return
        }
        
        // Ready Again Button (only handle touch when game is over)
        if readyAgainButton.contains(touchLocation) && isPaused {
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
    
    // MARK: - Game Over and Reset Logic
    func gameOver() {
        // Pause the game
        isPaused = true
        
        // Show "Ready Again?" button
        readyAgainButton.isHidden = false
    }
    
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
        
        // Set up BossGuy movement action again
        let moveLeft = SKAction.moveBy(x: -frame.width / 2 + bossGuy.size.width / 2, y: 0, duration: 4.0)
        let moveRight = SKAction.moveBy(x: frame.width / 2 - bossGuy.size.width / 2, y: 0, duration: 4.0)
        let stayInPlace = SKAction.wait(forDuration: 1.0)
        
        let randomMoveAction = SKAction.sequence([moveLeft, stayInPlace, moveRight, stayInPlace])
        bossMoveAction = SKAction.repeatForever(randomMoveAction)
        
        bossGuy.run(SKAction.repeatForever(bossMoveAction))
        
        // Resume game
        isPaused = false
    }
}
