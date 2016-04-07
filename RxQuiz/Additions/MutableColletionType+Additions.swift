//
//  MutableColletionType+Additions.swift
//  RxQuiz
//
//  Created by nakazy on 2016/03/31.
//  Copyright © 2016年 nakazy. All rights reserved.
//

import Foundation

extension MutableCollectionType where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }

        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}