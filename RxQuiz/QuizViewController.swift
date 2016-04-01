//
//  QuizViewController.swift
//  RxQuiz
//
//  Created by nakazy on 2016/03/31.
//  Copyright © 2016年 nakazy. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class QuizViewController: UIViewController {
    let answers = ["merge", "map", "reduce", "filter", "concat", "zip"]
    let disposeBag = DisposeBag()
    @IBOutlet weak var beforeImageView: UIImageView!
    @IBOutlet weak var afterImageView: UIImageView!
    @IBOutlet weak var answerButton1: UIButton!
    @IBOutlet weak var answerButton2: UIButton!
    @IBOutlet weak var answerButton3: UIButton!
    @IBOutlet weak var answerButton4: UIButton!
    private var answer: String!
    var questions: [Question] = []
    var count = 0 {
        didSet {
            setQuestion()
            setAnswers()
        }
    }

    private var buttons: [UIButton]  {
        return [answerButton1, answerButton2, answerButton3, answerButton4]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let path = NSBundle.mainBundle().pathForResource("Quiz", ofType: "json")
        let data = NSData(contentsOfFile: path!)
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
            let array = json.objectForKey("questions") as! NSArray
            for element in array {
                questions.append(Question(before_image: element["before_image"] as! String, after_image: element["after_image"] as! String, answer: element["answer"] as! String))
            }
        } catch  {
            print(error)
        }
        setQuestion()
        setAnswers()
        setButtonAction()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func checkAnswer(myAnswer: String) -> Bool {
        return myAnswer == answer
    }

    private func setButtonAction() {
        buttons.forEach { button in
            button.rx_tap
                .subscribeNext { [unowned self] in
                    if(self.checkAnswer(button.titleLabel!.text!)) {
                        print("seikai")
                    }
                    self.count += 1
                }
                .addDisposableTo(disposeBag)
        }
    }

    private func setQuestion() {
        let question = questions[count]
        answer = question.answer
        beforeImageView.image = UIImage(named: question.before_image)
        afterImageView.image = UIImage(named: question.after_image)
    }

    private func setAnswers() {
        let answer = questions[count].answer
        let ans = answers.filter { $0 != answer }.shuffle()[0...2]
        let an = [answer, ans[0], ans[1], ans[2]].shuffle()
        buttons.enumerate().forEach{ (number, button) in
            button.setTitle(an[number], forState: .Normal)
        }
    }
}

