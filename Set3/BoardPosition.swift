//
//  BoardPosition.swift
//  SetApp
//
//  Created by davida on 1/2/19.
//  Copyright © 2019 davida. All rights reserved.
//

import Foundation

struct BoardPosition {
    var card: Card?
    var state = State.unselected

    enum State {
        case unselected, selected, dealt, successful, failed
    }
}
