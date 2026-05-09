//
//  Item.swift
//  mela
//
//  Created by Viktor Luna on 5/9/26.
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
