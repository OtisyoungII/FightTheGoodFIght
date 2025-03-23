//
//  GamesViewController.swift
//  FightTheGoodFIght
//
//  Created by Otis Young on 3/20/25.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the SKView
        let skView = SKView(frame: self.view.frame)

        // Create and configure the GameScene
        let scene = GameScene(size: skView.frame.size)
        scene.scaleMode = .resizeFill

        // Present the scene
        skView.presentScene(scene)

        // Add the SKView as a subview
        self.view.addSubview(skView)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
