//
//  Item.swift
//  GroceryApp
//
//  Created by Sajid Reshmi on 27/04/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
