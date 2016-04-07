//
//  CollectionType+Additions.swift
//  RxQuiz
//
//  Created by nakazy on 2016/03/31.
//  Copyright © 2016年 nakazy. All rights reserved.
//

import Foundation

extension CollectionType {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Generator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}