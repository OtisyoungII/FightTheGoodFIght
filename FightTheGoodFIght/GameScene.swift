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
    static let Paddle: UInt32 = 0b1       // 1
    static let Bomb: UInt32 = 0b10        // 2
    static let Explosion: UInt32 = 0b100  // 4
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    var paddle: SKSpriteNode!
    var bombs: [SKSpriteNode] = []
    var scoreLabel: SKLabelNode!
    var score = 0
    var lifeLabel: SKLabelNode!
    var lives = 3  // Player starts with 3 lives
    var explosionTextures: [SKTexture] = []
    var bombTimer: Timer?
    var bombCount = 1
    var difficultyIncreaseTime: TimeInterval = 15 // Increase difficulty every 15 seconds
    var bossGuy: SKSpriteNode!  // Boss character
    var bossMoveAction: SKAction!
    var bossFakeOutAction: SKAction!
    
    // MARK: - Scene Setup
    override func didMove(to view: SKView) {
        // Set up the background
        let backdrop = SKSpriteNode(imageNamed: "BackDrop")
        backdrop.position = CGPoint(x: frame.midX, y: frame.midY)
        backdrop.zPosition = -1
        backdrop.size = CGSize(width: frame.size.width, height: frame.size.height)
        addChild(backdrop)
        
        // Set up paddle (Catcher asset)
        paddle = SKSpriteNode(imageNamed: "Catcher")
        paddle.size = CGSize(width: 100, height: 20)
        paddle.position = CGPoint(x: frame.midX, y: 50)
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.isDynamic = false  // The paddle shouldn't be affected by gravity
        paddle.physicsBody?.categoryBitMask = PhysicsCategory.Paddle
        paddle.physicsBody?.contactTestBitMask = PhysicsCategory.Bomb
        paddle.physicsBody?.collisionBitMask = 0
        addChild(paddle)
        
        // Set up score label
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.height - 40)
        addChild(scoreLabel)
        
        // Set up life label
        lifeLabel = SKLabelNode(text: "Lives: \(lives)")
        lifeLabel.fontSize = 32
        lifeLabel.fontColor = .white
        lifeLabel.position = CGPoint(x: frame.midX, y: frame.height - 80)
        addChild(lifeLabel)
        
        // Load explosion assets
        loadExplosionTextures()
        
        // Start bomb timer
        bombTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(dropBomb), userInfo: nil, repeats: true)
        
        // Set up gravity and physics world
        physicsWorld.gravity = CGVector(dx: 0, dy: -1)
        physicsWorld.contactDelegate = self
        
        // Create and set BossGuy
        bossGuy = SKSpriteNode(imageNamed: "BossGuy")
        bossGuy.size = CGSize(width: 100, height: 100)
        bossGuy.position = CGPoint(x: frame.midX, y: frame.height - 150)
        addChild(bossGuy)
        
        // Boss horizontal movement action
        let moveLeft = SKAction.moveBy(x: -frame.width + 100, y: 0, duration: 3.0) // Move across the full width of the screen
        let moveRight = SKAction.moveBy(x: frame.width - 100, y: 0, duration: 3.0)
        let stayInPlace = SKAction.wait(forDuration: 1.0) // Stay in place before moving again
        let randomMoveAction = SKAction.sequence([moveLeft, stayInPlace, moveRight, stayInPlace])
        bossMoveAction = SKAction.repeatForever(randomMoveAction)
        
        // Boss Fake-out (don't drop bombs)
        let fakeOut = SKAction.sequence([stayInPlace, stayInPlace]) // Boss doesn't drop bombs during fake-out
        bossFakeOutAction = SKAction.repeatForever(fakeOut)
        
        // Make the Boss move horizontally and do fake-out
        bossGuy.run(SKAction.repeatForever(bossMoveAction))
        
        // Increase difficulty over time
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: difficultyIncreaseTime),
                SKAction.run { self.increaseDifficulty() }
            ])
        ))
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
        // Drop up to 2 bombs at a time from BossGuy, limited to the width of the paddle
        for _ in 0..<min(2, bombCount) {
            let newBomb = SKSpriteNode(imageNamed: "Records")
            newBomb.size = CGSize(width: 70, height: 70) // Set bomb size to 70x70
            newBomb.position = CGPoint(x: bossGuy.position.x + CGFloat.random(in: -50..<50), y: bossGuy.position.y - 50)
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
    }
    
    // MARK: - Increase Difficulty
    func increaseDifficulty() {
        difficultyIncreaseTime -= 1  // Shorten the interval between bomb drops (faster bombs)
        
        // Optionally, increase gravity or bomb drop speed, making the game harder
        physicsWorld.gravity = CGVector(dx: 0, dy: -1 - CGFloat(difficultyIncreaseTime / 10)) // Increase gravity
    }
    
    // MARK: - Update Scene
    override func update(_ currentTime: TimeInterval) {
        // Check for bombs that fall off the screen (missed bombs)
        for bomb in bombs {
            if bomb.position.y < 0 {
                triggerExplosion(at: bomb.position)
                bomb.removeFromParent()  // Remove missed bomb
                
                // Lose a life when a bomb is missed
                lives -= 1
                lifeLabel.text = "Lives: \(lives)"
                
                if lives <= 0 {
                    gameOver()
                }
            }
        }
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
    
    // MARK: - Life Management and Game Over
    func gameOver() {
        // Game over logic here (e.g., stop bomb timer, show game over screen)
        bombTimer?.invalidate()
        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(gameOverLabel)
        
        // Optionally, provide a restart or exit option
    }
    
    // MARK: - Touch Handling (for horizontal paddle movement)
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        // Update paddle position based on touch location (only in X-axis)
        paddle.position.x = touchLocation.x
    }
}
