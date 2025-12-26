//
//  Item.swift
//  reflection
//
//  Created by 若生 翼 on 2025/12/26.
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
