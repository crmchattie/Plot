//
//  Sequence+Utility.swift
//  Plot
//
//  Created by Botond Magyarosi on 28.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import Foundation

extension Sequence {
    public func grouped<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [T: [Element]] {
        return .init(grouping: self, by: { $0[keyPath: keyPath] })
    }
}
