//
//  Card.swift
//  SetApp
//
//  Created by davida on 1/1/19.
//  Copyright © 2019 davida. All rights reserved.
//

import Foundation
import UIKit

struct Card {
    var symbol: Symbol?
    var pipCount: PipCount?
    var color: Color?
    var shading: Shading?
    
    enum Symbol: String {
        case triangle = "▲"
        case circle = "●"
        case square = "■"
        
        static var all = [Symbol.triangle, .circle, .square]
    }
    
    enum PipCount: Int {
        case one = 1
        case two = 2
        case three = 3
        
        static var all = [PipCount.one, .two, .three]
    }
    
    enum Color: String {
        case red
        case green
        case purple
        
        static var all = [Color.red, .green, .purple]
        
        func uiColor() -> UIColor {
            switch self.rawValue {
            case "red": return #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
            case "green": return  #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
            case "purple": return  #colorLiteral(red: 0.5791940689, green: 0.1280144453, blue: 0.5726861358, alpha: 1)
            default: return  #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
            }
        }
    }
    
    enum Shading: String {
        case filled
        case striped
        case outlined
        
        static var all = [Shading.filled, .striped, .outlined]
    }
    
} //Card
