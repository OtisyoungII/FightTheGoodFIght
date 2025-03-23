//
//  GameControllerWrapper.swift
//  FightTheGoodFIght
//
//  Created by Otis Young on 3/20/25.
//


import SwiftUI
import UIKit

struct GameViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GameViewController {
        return GameViewController()
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
        // You can update the view controller here if needed
    }
}
