//
//  Collection+Utility.swift
//  Plot
//
//  Created by Botond Magyarosi on 21.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

extension Array {
    
    mutating func shiftLeft(_ places: Int) {
        guard places > 0 else { return }
        for _ in 0..<places {
            self.append(self.removeFirst())
        }
    }
}
