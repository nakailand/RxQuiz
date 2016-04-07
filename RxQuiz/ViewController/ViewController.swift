//
//  ViewController.swift
//  RxQuiz
//
//  Created by nakazy on 2016/03/31.
//  Copyright © 2016年 nakazy. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.rx_tap
            .subscribeNext {
                let storyBoard = UIStoryboard(name: "Quiz", bundle: NSBundle.mainBundle())
                let quizViewController = storyBoard.instantiateInitialViewController() as! QuizViewController
                self.addChildViewController(quizViewController)
                self.view.addSubview(quizViewController.view)
                self.didMoveToParentViewController(self)
        }
        .addDisposableTo(disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

