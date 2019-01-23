//
//  ViewController.swift
//  Set3
//
//  Created by davida on 1/22/19.
//  Copyright © 2019 davida. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //Create a grid to hold 12 initial cards
    lazy var grid = Grid(layout: Grid.Layout.dimensions(rowCount: 3, columnCount: 4), frame: BoardView.bounds)
    
    var game = Set3()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        game.newGame()
        syncViewUsingModel()
    }
    
    @IBOutlet weak var BoardView: UIView!
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var dealButton: UIButton! { didSet { dealButton.layer.cornerRadius = 8 } }
    
    @IBAction func dealButton(_ sender: UIButton) {
        game.clickDealCards()
        syncViewUsingModel()
    }
    
    @IBOutlet weak var newGameButton: UIButton! { didSet { newGameButton.layer.cornerRadius = 8 } }
    
    @IBAction func newGameButton(_ sender: UIButton) {
        game.newGame()
        syncViewUsingModel()
    }
    
    @IBOutlet var cardButtons: [UIButton]!
    
    @IBAction func touchCard(_ sender: UIButton) {
        if let position = cardButtons.index(of: sender) {
            game.clickCard(atPosition: position)
            syncViewUsingModel()
        }
    }
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var hintsButton: UIButton! { didSet { hintsButton.layer.cornerRadius = 8 } }
    
    @IBAction func hintButton(_ sender: UIButton) {
        game.clickHintButton()
        syncViewUsingModel()
    }
    private func syncViewUsingModel() {
        //Show the cards that need to be shown, hiding all others
        for atPosition in 0..<game.board.count {
            if game.board[atPosition].card == nil {
                //No card to show (so hide it)
                cardButtons[atPosition].setAttributedTitle(nil, for: UIControl.State.normal)
                cardButtons[atPosition].backgroundColor = UIColor(cgColor: view.backgroundColor!.cgColor)
                cardButtons[atPosition].layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                cardButtons[atPosition].layer.borderWidth = 1
            } else {
                //Sets the Face that will be displayed on the button for the Card at this position
                cardButtons[atPosition].setAttributedTitle(game.buildCardFace(atPosition: atPosition), for: UIControl.State.normal)
                cardButtons[atPosition].titleLabel!.numberOfLines = 0
                //Adjust the border to highlight the position if needed
                switch game.board[atPosition].state {
                case .dealt: cardButtons[atPosition].layer.borderColor = #colorLiteral(red: 0.9994240403, green: 0.9855536819, blue: 0, alpha: 1)
                case .unselected: cardButtons[atPosition].layer.borderColor = view.backgroundColor!.cgColor
                case .selected: cardButtons[atPosition].layer.borderColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
                case .successful: cardButtons[atPosition].layer.borderColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
                case .failed: cardButtons[atPosition].layer.borderColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
                }
                cardButtons[atPosition].layer.borderWidth = 5
                cardButtons[atPosition].backgroundColor = UIColor.white
                
                dealButton.isEnabled = game.cards.count > 0 && game.availableBoardPosition != nil
                dealButton.titleLabel?.isEnabled = game.cards.count > 0 && game.availableBoardPosition != nil
            }
        }
        scoreLabel.text = "Score: \(game.score)"
        statusLabel.text = game.status
        hintsButton.setTitle(game.hintsButtonLabel, for:  UIControl.State.normal)
    }
    
} //ViewController

extension Int {
    var arc4random: Int {
        if self > 0 {
            return Int(arc4random_uniform(UInt32(self)))
        } else if self < 0 {
            return -Int(arc4random_uniform(UInt32(abs(self))))
        } else {
            return 0
        }
    }
}
