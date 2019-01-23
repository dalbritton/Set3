//
//  BoardPosition.swift
//  Set3
//
//  Created by davida on 1/22/19.
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
