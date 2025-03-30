//
//  PaddleController.swift
//  FightTheGoodFIght
//
//  Created by Otis Young on 3/30/25.
//

import SpriteKit


class PaddleController: SKNode {
    private var paddle: SKSpriteNode
    init (paddle: SKSpriteNode) {
        self.paddle = paddle
        
    }
    func movePaddle(to position: CGPoint) {
        paddle.position.x = position.x
    }
}
