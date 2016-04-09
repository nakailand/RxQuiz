//
//  Question.swift
//  RxQuiz
//
//  Created by nakazy on 2016/03/31.
//  Copyright © 2016年 nakazy. All rights reserved.
//

import Foundation
import Argo
import Curry

struct Question {
    let beforeImage: String
    let afterImage: String
    let answer: String
}

extension Question: Decodable  {
    static func decode(j: JSON) -> Decoded<Question> {
        return curry(Question.init)
            <^> j <| "beforeImage"
            <*> j <| "afterImage"
            <*> j <| "answer"
    }
}

func JSONFromFile(file: String) -> AnyObject? {
    return NSBundle.mainBundle().pathForResource(file, ofType: "json")
        .flatMap { NSData(contentsOfFile: $0) }
        .flatMap(JSONObjectWithData)
}

func JSONObjectWithData(data: NSData) -> AnyObject? {
    do { return try NSJSONSerialization.JSONObjectWithData(data, options: []) }
    catch { return .None }
}
