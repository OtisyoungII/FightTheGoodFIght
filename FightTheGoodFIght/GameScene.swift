//
//  GameScene.swift
//  FightTheGoodFIght
//
//  Created by Otis Young on 3/20/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // MARK: - Properties
    var paddle: SKSpriteNode!
    var bomb: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var score = 0
    
    // MARK: - Scene Setup
    override func didMove(to view: SKView) {
        // Set up the paddle
        paddle = SKSpriteNode(color: .blue, size: CGSize(width: 100, height: 20))
        paddle.position = CGPoint(x: frame.midX, y: 50) // Start near the bottom of the screen
        addChild(paddle)
        
        // Set up the bomb (which will fall)
        bomb = SKSpriteNode(color: .red, size: CGSize(width: 30, height: 30))
        bomb.position = CGPoint(x: CGFloat.random(in: 0..<frame.width), y: frame.height - 50)
        addChild(bomb)
        
        // Set up score label
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.height - 40)
        addChild(scoreLabel)
        
        // Set up gravity and physics world
        physicsWorld.gravity = CGVector(dx: 0, dy: -1) // simulate gravity
        physicsWorld.contactDelegate = self
    }
    
    // MARK: - Update Scene
    override func update(_ currentTime: TimeInterval) {
        // Move bomb downwards
        bomb.position.y -= 3
        
        // If bomb goes off screen, reset it
        if bomb.position.y < 0 {
            bomb.position = CGPoint(x: CGFloat.random(in: 0..<frame.width), y: frame.height - 50)
        }
        
        // Check for collision between paddle and bomb
        if bomb.frame.intersects(paddle.frame) {
            score += 1
            scoreLabel.text = "Score: \(score)"
            // Reset bomb position
            bomb.position = CGPoint(x: CGFloat.random(in: 0..<frame.width), y: frame.height - 50)
        }
    }
    
    // MARK: - Touch Handling (for horizontal paddle movement)
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        // Update paddle position based on touch location (only in X-axis)
        paddle.position.x = touchLocation.x
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Do something when touch begins (optional)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Do something when touch ends (optional)
    }
    
}

// MARK: - Physics Contact Handling
extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // Handle collisions (e.g., between paddle and bombs)
        if contact.bodyA.node == bomb || contact.bodyB.node == bomb {
            score += 1
            scoreLabel.text = "Score: \(score)"
            bomb.position = CGPoint(x: CGFloat.random(in: 0..<frame.width), y: frame.height - 50)
        }
    }
}
