//
//  Set3.swift
//  Set3
//
//  Created by davida on 1/22/19.
//  Copyright © 2019 davida. All rights reserved.
//

import Foundation
import GameplayKit

struct Set3 {
    private var numberOfBoardPositions = Constants.HowManyBoardPositions
    private var numberOfCardsInDeck = Constants.HowManyCardsInDeck
    private var hints = [(Int, Int, Int)]()
    
    private var allPositionsHavingCards: [Int]? {
        let positions = board.indices.filter {board[$0].card != nil}
        return positions.count > 0 ? positions : nil
    }

    //Keep track of how many "extra" sets of cards have been dealt so that a penalty can be imposed for showing more than the initial cards (we con't count the click if unless there is no possible Set among the currently visible cards)
    public var clickDealCardsCounter = 0
    
    //Keep track of whether hints are being shown so that a penalty can be imposed
    public var hintsAreVisible = false  //(no penalty for peeking as long as hints are hidden before scoring occurs)
    
    public var score = 0
    
    public lazy var cards = [Card]()
    
    //A board that will contain positions upon which the game will be played
    public var board = [BoardPosition]()
    
    public var status = ""
    public var hintsButtonLabel = ""
    
    public mutating func newGame() {
        try! validateStartingValues()
        
        score = 0
        
        //Create a new deck of cards; shuffled into a random sequence
        createCardDeck(numberOfCards: numberOfCardsInDeck)
        
        //Create a board containing BoardPositions upon which the game will be played
        board = [BoardPosition]()
        for _ in 1...numberOfBoardPositions {
            board.append(BoardPosition())
        }
        
        //Deal no more than 12 cards to start the game
        dealCards(numberOfCards: numberOfCardsInDeck < Constants.InitialCardsToDeal
            ? numberOfCardsInDeck : Constants.InitialCardsToDeal, withBorder: false)
        
        clearHints()
    }
    
    public mutating func clickDealCards() {
        if generateHints() != 0 {
            clickDealCardsCounter += 1  //Impose the penalty for manually dealing cards ONLY when there are possible Sets among the Card currently shown on the playing board
        }
        dealCards(numberOfCards: 3, withBorder: true)
    }
    
    private mutating func dealCards(numberOfCards: Int, withBorder: Bool) {
        clearBorders(withState: BoardPosition.State.dealt)
        
        //If there is a selected "successful" set of three cards then remove them from the board
        if let positions = selectedPositions() {
            if positions.count == 3 {
                let successful = validate(for: positions)
                if successful {
                    for index in positions.indices {
                        board[positions[index]].card = nil
                    }
                }
            }
        }
        
        //Now deal the new cards
        var count = 0
        for _ in 1...numberOfCards {
            if let position = availableBoardPosition {
                if cards.count > 0 {
                    let card = cards.remove(at:cards.count.arc4random)
                    board[position].card = card
                    board[position].state = withBorder ? .dealt : .unselected
                    count += 1
                }
            }
        }
        clearHints()
        status = "\(count) new cards have been dealt"
    }
    
    private mutating func clearBorders(withState: BoardPosition.State) {
        //Clear all the borders having "withState"
        if let positions = allPositionsHavingCards {
            for index in positions.indices {
                if board[positions[index]].state == withState {
                    board[positions[index]].state = .unselected
                }
            }
        }
    }

    public func buildCardFace(atPosition: Int) -> NSAttributedString {
        let theCard = board[atPosition].card!
        var label = ""
        for _ in 1...theCard.pipCount!.rawValue {
            label += (label.count > 0 ? "\n" : "") + theCard.symbol!.rawValue
        }
        let attributes: [NSAttributedString.Key : Any] = [
            .strokeColor : theCard.color!.uiColor(),
            .strokeWidth : theCard.shading!.rawValue == "filled"
                || theCard.shading!.rawValue == "striped" ? -7 : 7,
            .foregroundColor : theCard.color!.uiColor().withAlphaComponent(theCard.shading!.rawValue == "striped" ? 0.15 : 1.0)
        ]
        return NSAttributedString(string:  label, attributes: attributes)
    }
    
    public mutating func clickCard(atPosition: Int ) {
        clearBorders(withState: BoardPosition.State.dealt)
        
        //Clear the status unless there are hints displayed
        if !hintsAreVisible { status = "" }
        
        //If there are currently three selected card positions
        var successfulSet = false
        if let positions = selectedPositions() {
            if positions.count == 3 {
                for index in positions.indices {
                    switch board[positions[index]].state {
                    //Then remove if they're successful
                    case .successful:
                        board[positions[index]].card = nil
                        successfulSet = true
                    //Else unselect them
                    case .failed:
                        board[positions[index]].state = .unselected
                    default: break
                    }
                }
                if successfulSet {
                    dealCards(numberOfCards: 3, withBorder: true)
                    if positions.contains(atPosition) { return }
                }
            }
        }
        
        //If the selected BoardPosition contains a Card then flip its Selected state
        if board[atPosition].card != nil  {
            switch board[atPosition].state {
            case .unselected, .dealt:
                board[atPosition].state = .selected
            case .selected:
                board[atPosition].state = .unselected
            default:
                board[atPosition].state = .unselected
            }
        }
        
        //If there are now three cards "selected" then "validate" them
        if let positions = selectedPositions() {
            if positions.count == 3 {
                let successful = validate(for: positions)
                for index in positions.indices {
                    board[positions[index]].state = successful ? .successful : .failed
                }
                
                let thisScore = successful ? Constants.ScoreForSuccessfulSet                    //Award points for a "successful" Set
                    - (clickDealCardsCounter*Constants.PenaltyForDealingEachAdditional)        //Deduct for each time user has dealt more cards
                    - (hintsAreVisible ? Constants.PenaltyForScoringWhileHintsAreVisible : 0)   //Penalize for scoring while hints are displayed
                    : -Constants.PenaltyForFailedSet                                            //Penalize for a "failed" Set
                status = "\(thisScore) points recorded for this Set"
                score += thisScore
            }
        }
        
    }
    
    private mutating func clearHints() {
        hints.removeAll()
        hintsButtonLabel = "Hints"
        hintsAreVisible = false
        status = ""
    }
    
    public mutating func clickHintButton() {
        //Clicking hints toggles their visibility
        if hints.count > 0 {
            clearHints()
        } else {
            if generateHints() == 0 {
                status = "No Sets among the cards shown"
                hintsButtonLabel = "Hints"
            } else {
                var hintString = ""
                for index in hints.indices {
                    let selection: (card1:Int, card2: Int , card3:Int ) = hints[index]
                    hintString += "\(selection.card1+1),\(selection.card2+1),\(selection.card3+1)   "
                }
                status = hintString
                hintsButtonLabel = "Hints (\(hints.count))"
            }
            hintsAreVisible = hints.count > 0
        }
    }
    
    public mutating func generateHints() -> Int {
        //Build a Set of all positions containing cards; exclude cards in "successful" Sets
        var positions = [Int]()
        for index in board.indices {
            if board[index].card != nil && board[index].state != .successful {
                positions.append(index)
            }
        }
        
        //No chance of a hint if there are fewer than 3 cards
        if positions.count < 3 {
            hints.removeAll()
        } else {
            var counter = 0
            var aCardSet = [Int]()
            for card1Position in 0..<positions.count-2 {
                for card2Position in card1Position+1..<positions.count-1 {
                    for card3Position in card2Position+1..<positions.count {
                        counter += 1
                        aCardSet.removeAll()
                        aCardSet.append(positions[card1Position])
                        aCardSet.append(positions[card2Position])
                        aCardSet.append(positions[card3Position])
                        if validate(for: aCardSet) {
                            hints.append((aCardSet[0], aCardSet[1], aCardSet[2]))
                        }
                    }
                }
            }
        }
        
        return hints.count
    }
    
    public var availableBoardPosition: Int? {
        //Build an array of available board positions
        var positions = [Int]()
        for index in board.indices {
            //An empty (available) position contains no Card or contains a .successfully matched card
            if board[index].card == nil || board[index].state == .successful {
                positions.append(index)
            }
        }
        if positions.count > 0 {
            //Build a shuffled sequence based upon the number of available board positions
            let shuffledSequence = GKShuffledDistribution(forDieWithSideCount: positions.count)
            return positions[shuffledSequence.nextInt() - 1]
        } else {
            return nil
        }
    }
    
    public enum ApplicationError: Error, CustomStringConvertible {
        case rangeException(varName: String, value: Int, range: ClosedRange<Int>)
        
        var description: String {
            var text = "ApplicationError: "
            switch self {
            case .rangeException(let varName, let value, let range):
                text += "\(varName) [\(value)] must be in the range \(range)"
            }
            return text
        }
    }
    
    private func validateStartingValues() throws {
        //The application can handle a maximum of 24 board positions
        var range = 1...24
        if !range.contains(numberOfBoardPositions) {
            throw ApplicationError.rangeException(varName: "numberOfBoardPositions", value: numberOfBoardPositions, range: range)
        }
        
        //The application can handle a maximum of 81 playing cards
        range = 1...81
        if  !range.contains(numberOfCardsInDeck) {
            throw ApplicationError.rangeException(varName: "numberOfCardsInDeck", value: numberOfCardsInDeck, range: range)
        }
    }
    
    //Create a deck of cards; shuffled into a random sequence
    private mutating func createCardDeck(numberOfCards: Int) {
        cards.removeAll()
        for _ in 0..<numberOfCards {
            self.cards.append(Card())
        }
        //Get a list of random sequences to use for shuffling
        let shuffledSequence = GKShuffledDistribution(forDieWithSideCount: numberOfCards)
        for aSymbol in Card.Symbol.all {
            for aPipCount in Card.PipCount.all {
                for aColor in Card.Color.all {
                    for aShading in Card.Shading.all {
                        let index = shuffledSequence.nextInt() - 1
                        self.cards[index].symbol = aSymbol
                        self.cards[index].pipCount = aPipCount
                        self.cards[index].color = aColor
                        self.cards[index].shading = aShading
                    }
                }
            }
        }
    }
    
    private mutating func drawCardFromDeck() -> Card? {
        if cards.count > 0 {
            return cards.remove(at:cards.count.arc4random)
        } else {
            return nil
        }
    }
    
    private func selectedPositions() -> [Int]? {
        //Return an array of BoardPosition indices having "selected" states
        var positions = [Int]()
        for index in board.indices {
            if board[index].card != nil {
                switch board[index].state {
                case .selected, .failed, .dealt, .successful:
                    positions.append(index)
                default: break
                }
            }
        }
        return positions.count > 0 ? positions : nil
    }
    
    private func failedPositions() -> [Int]? {
        //Return an array of all BoardPosition indices having "failed" states
        var positions = [Int]()
        for index in board.indices {
            if board[index].card != nil && board[index].state == .failed {
                positions.append(index)
            }
        }
        return positions.count > 0 ? positions : nil
    }
    
    private func validate(for positions: [Int]) -> Bool {
        //A cardSet containing three cards and rating 4 is a valid Set
        var rating = 0
        if positions.count == 3 {
            let card1 = board[positions[0]].card!
            let card2 = board[positions[1]].card!
            let card3 = board[positions[2]].card!
            
            //They all have the same number or have three different numbers
            let pips: Set = [ card1.pipCount, card2.pipCount ]
            if (card1.pipCount == card2.pipCount && card2.pipCount == card3.pipCount)
                    || (card1.pipCount != card2.pipCount && !pips.contains(card3.pipCount) ) {
                rating += 1
            }
            
            //They all have the same symbol or have three different symbols
            let symbols: Set = [ card1.symbol, card2.symbol ]
            if (card1.symbol == card2.symbol && card2.symbol == card3.symbol)
                    || (card1.symbol != card2.symbol && !symbols.contains(card3.symbol) ) {
                rating += 1
            }
            
            //They all have the same shading or have three different shadings
            let shadings: Set = [ card1.shading, card2.shading ]
            if (card1.shading == card2.shading && card2.shading == card3.shading)
                    || (card1.shading != card2.shading && !shadings.contains(card3.shading) ) {
                rating += 1
            }
            
            //They all have the same color or have three different colors
            let colors: Set = [ card1.color, card2.color ]
            if (card1.color == card2.color && card2.color == card3.color)
                    || (card1.color != card2.color && !colors.contains(card3.color) ) {
                rating += 1
            }
        }
        
        return rating == 4
    }
    
} //Set3

extension Set3 {
    private struct Constants {
        static let HowManyBoardPositions = 24
        static let HowManyCardsInDeck = 81
        static let InitialCardsToDeal = 12
        static let ScoreForSuccessfulSet = 100
        static let PenaltyForFailedSet = 15
        static let PenaltyForDealingEachAdditional = 5
        static let PenaltyForScoringWhileHintsAreVisible = 25
    }
}
