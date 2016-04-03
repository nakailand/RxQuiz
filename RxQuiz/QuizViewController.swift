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
    var count = Variable<Int>(0)
    var correctCount = 0
    var startDate = NSDate()
    
    private var buttons: [UIButton]  {
        return [answerButton1, answerButton2, answerButton3, answerButton4]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareQuestions()
        setButtonAction()
        count.asObservable()
            .subscribeNext { [unowned self] count in
                if count == 2 {
                    self.showTime()
                    return
                }
                self.setQuestion(count)
                self.setAnswers(count)
            }
            .addDisposableTo(disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func restart() {
        self.prepareQuestions()
        self.count.value = 0
        self.correctCount = 0
        self.startDate = NSDate()
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
            self.restart()
        }
        alertController.addAction(okAction)
        alertController.addAction(shareAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func prepareQuestions() {
        let path = NSBundle.mainBundle().pathForResource("Quiz", ofType: "json")
        let data = NSData(contentsOfFile: path!)
        questions = []
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
            let array = json.objectForKey("questions") as! NSArray
            for element in array {
                questions.append(Question(before_image: element["before_image"] as! String, after_image: element["after_image"] as! String, answer: element["answer"] as! String))
            }
        } catch  {
            print(error)
        }
    }
    
    private func segueToStartViewController() {
        self.willMoveToParentViewController(nil)
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
    }

    private func checkAnswer(myAnswer: String) -> Bool {
        return myAnswer == answer
    }

    private func setButtonAction() {
        buttons.forEach { button in
            button.rx_tap
                .subscribeNext { [unowned self] in
                    if(self.checkAnswer(button.titleLabel!.text!)) {
                        self.correctCount += 1
                    }
                    self.count.value += 1
                }
                .addDisposableTo(disposeBag)
        }
    }

    private func setQuestion(count: Int) {
        let question = questions[count]
        answer = question.answer
        beforeImageView.image = UIImage(named: question.before_image)
        afterImageView.image = UIImage(named: question.after_image)
    }

    private func setAnswers(count: Int) {
        let answer = questions[count].answer
        let ans = answers.filter { $0 != answer }.shuffle()[0...2]
        let an = [answer, ans[0], ans[1], ans[2]].shuffle()
        buttons.enumerate().forEach{ (number, button) in
            button.setTitle(an[number], forState: .Normal)
        }
    }
}

