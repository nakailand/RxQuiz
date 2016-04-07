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
    private let answers = ["merge", "map", "reduce", "filter", "concat", "zip"]
    private let disposeBag = DisposeBag()
    @IBOutlet weak var beforeImageView: UIImageView!
    @IBOutlet weak var afterImageView: UIImageView!
    @IBOutlet weak var answerButton1: UIButton!
    @IBOutlet weak var answerButton2: UIButton!
    @IBOutlet weak var answerButton3: UIButton!
    @IBOutlet weak var answerButton4: UIButton!
    private var answer: String!
    private let questions = Variable<[Question]>([])
    private let currentQuestionIndex = Variable<Int>(0)
    private var correctCount = 0
    private var startDate = NSDate()
    private let currentQuestion = Variable<Question>(Question(beforeImage: "", afterImage: "", answer: ""))
    private let currentAnswer = Variable<String>("")
    
    private var buttons: [UIButton]  {
        return [answerButton1, answerButton2, answerButton3, answerButton4]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        questions.asObservable()
            .filter { $0.isEmpty }
            .observeOn(MainScheduler.instance)
            .subscribeNext { [unowned self] _ in
                let path = NSBundle.mainBundle().pathForResource("Quiz", ofType: "json")
                let data = NSData(contentsOfFile: path!)
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
                    let questions = json.objectForKey("questions") as! NSArray
                    questions.forEach { [unowned self] question in
                        self.questions.value.append(
                            Question(
                                beforeImage: question["beforeImage"] as! String,
                                afterImage: question["afterImage"] as! String,
                                answer: question["answer"] as! String
                            )
                        )
                    }
                } catch  {
                    print(error)
                }
            }
            .addDisposableTo(disposeBag)
        
        buttons.forEach { button in
            button.rx_tap
                .subscribeNext { [unowned self] in
                    if self.isCorrect(button.titleLabel!.text!) {
                        self.correctCount += 1
                    }
                    self.currentQuestionIndex.value += 1
                }
                .addDisposableTo(disposeBag)
        }
        
        currentQuestionIndex.asObservable()
            .subscribeNext { [unowned self] count in
                switch count {
                case 2:
                    self.showTime()
                default:
                    let question = self.questions.value[count]
                    self.currentQuestion.value = question
                    self.currentAnswer.value = question.answer
                }
            }
            .addDisposableTo(disposeBag)
        
        currentAnswer.asObservable()
            .subscribeNext { [unowned self] answer in
                let incorrectAnswers = self.answers.filter { $0 != answer }.shuffle()[0...2]
                let answerArray = [answer, incorrectAnswers[0], incorrectAnswers[1], incorrectAnswers[2]].shuffle()
                self.buttons.enumerate().forEach{ (number, button) in
                    button.setTitle(answerArray[number], forState: .Normal)
                }
            }
            .addDisposableTo(disposeBag)
        
        currentQuestion.asObservable()
            .subscribeNext { [unowned self] question in
                self.beforeImageView.image = UIImage(named: question.beforeImage)
                self.afterImageView.image = UIImage(named: question.afterImage)
            }
            .addDisposableTo(disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func restart() {
        questions.value.removeAll()
        currentQuestionIndex.value = 0
        correctCount = 0
        startDate = NSDate()
    }
    
    private func showTime() {
        let time = NSDate().timeIntervalSinceDate(self.startDate) // 現在時刻と開始時刻の差
        let hh = Int(time / 3600)
        let mm = Int((time - Double(hh * 3600)) / 60)
        let ss = time - Double(hh * 3600 + mm * 60)
        let timeString = String(format: "%02d:%02d:%f", hh, mm, ss)
        
        let alertController = UIAlertController(title: "10問中\(correctCount)問正解", message:
            "タイム \(timeString)", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "もう一度", style: .Default) { action in
            self.restart()
        }
        let shareAction = UIAlertAction(title: "Twitterでシェアする", style: .Default) { action in
        }
        alertController.addAction(okAction)
        alertController.addAction(shareAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func isCorrect(myAnswer: String) -> Bool {
        return myAnswer == currentAnswer.value
    }
}
