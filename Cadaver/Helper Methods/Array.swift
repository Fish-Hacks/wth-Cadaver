//
//  Array.swift
//  Cadaver
//
//  Created by Jia Chen Yee on 20/4/23.
//

import Foundation

extension Array {
    @discardableResult
    mutating func removeFirst(where predicate: (Element) -> Bool) -> Element? {
        if let index = self.firstIndex(where: predicate) {
            return self.remove(at: index)
        }
        return nil
    }
}
