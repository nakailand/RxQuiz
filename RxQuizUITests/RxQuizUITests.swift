//
//  RxQuizUITests.swift
//  RxQuizUITests
//
//  Created by nakazy on 2016/03/31.
//  Copyright © 2016年 nakazy. All rights reserved.
//

import XCTest

class RxQuizUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
        XCUIApplication().buttons["Start"].tap()
        snapshot("0Launch")
    }
    
}
