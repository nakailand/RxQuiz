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
import Argo
import AVFoundation

final class QuizViewController: UIViewController {
    private var message = ""
    private var startDate = NSDate()
    @IBOutlet weak var beforeImageView: UIImageView!
    @IBOutlet weak var afterImageView: UIImageView!
    @IBOutlet weak var answerButton1: UIButton!
    @IBOutlet weak var answerButton2: UIButton!
    @IBOutlet weak var answerButton3: UIButton!
    @IBOutlet weak var answerButton4: UIButton!
    
    private let answers = [
        "merge",
        "map(x => 10 * x)",
        "reduce",
        "filter",
        "concat",
        "zip",
        "take(2)",
        "takeLast(1)",
        "sample",
        "scan",
        "combineLatest",
        "concat",
        "reduce((x, y) => x + y)",
        "findIndex(x => x > 10)"
    ]
    
    private let disposeBag = DisposeBag()
    private let questions = Variable<[Question]>([])
    private let currentQuestionIndex = Variable<Int>(0)
    private let correctAnswerCount = Variable<Int>(0)
    private let currentQuestion = Variable<Question>(Question(beforeImage: "", afterImage: "", answer: ""))
    private let currentAnswer = Variable<String>("")
    
    private var buttons: [UIButton]  {
        return [answerButton1, answerButton2, answerButton3, answerButton4]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let correctSoundPath = NSBundle.mainBundle().pathForResource("correct", ofType: "mp3"),
            correctSoundAudioPlayer = try? AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: correctSoundPath), fileTypeHint: "mp3") else {
                return
        }
        correctSoundAudioPlayer.prepareToPlay()
        
        guard let incorrectSoundPath = NSBundle.mainBundle().pathForResource("incorrect", ofType: "mp3"),
            incorrectSoundAudioPlayer = try? AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: incorrectSoundPath), fileTypeHint: "mp3") else {
                return
        }
        incorrectSoundAudioPlayer.prepareToPlay()
        
        questions.asObservable()
            .filter { $0.isEmpty }
            .observeOn(MainScheduler.instance)
            .subscribeNext { [unowned self] _ in
                let questions: [Question] = (JSONFromFile("Quiz")?["questions"].flatMap(decode))!
                questions.shuffle().toObservable()
                    .subscribeNext {
                        self.questions.value.append($0)
                }
                .addDisposableTo(self.disposeBag)
            }
            .addDisposableTo(disposeBag)
        
        buttons.forEach { button in
            button.rx_tap
                .subscribeNext { [unowned self] in
                    if button.titleLabel!.text! == self.currentAnswer.value {
                        self.correctAnswerCount.value += 1
                        correctSoundAudioPlayer.play()
                    } else {
                        incorrectSoundAudioPlayer.play()
                    }
                    self.currentQuestionIndex.value += 1
                }
                .addDisposableTo(disposeBag)
        }
        
        currentQuestionIndex.asObservable()
            .subscribeNext { [unowned self] count in
                switch count {
                case self.questions.value.endIndex:
                    let time = NSDate().timeIntervalSinceDate(self.startDate)
                    let hh = Int(time / 3600)
                    let mm = Int((time - Double(hh * 3600)) / 60)
                    let ss = time - Double(hh * 3600 + mm * 60)
                    let timeString = String(format: "%02d:%02d:%f", hh, mm, ss)
                    
                    let alertController = UIAlertController(
                        title: "10問中\(self.correctAnswerCount.value)問正解",
                        message: "タイム \(timeString)\n\(self.message)",
                        preferredStyle: .Alert
                    )
                    
                    let okAction = UIAlertAction(title: "もう一度", style: .Default) { _ in
                        self.questions.value.removeAll()
                        self.currentQuestionIndex.value = 0
                        self.correctAnswerCount.value = 0
                        self.startDate = NSDate()
                    }
                    
                    let shareAction = UIAlertAction(title: "Twitterでシェアする", style: .Default) { _ in
                    }
                    alertController.addAction(okAction)
                    alertController.addAction(shareAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                default:
                    let question = self.questions.value[count]
                    self.currentQuestion.value = question
                    self.currentAnswer.value = question.answer
                }
            }
            .addDisposableTo(disposeBag)
        
        currentQuestion.asObservable()
            .subscribeNext { [unowned self] question in
                self.beforeImageView.image = UIImage(named: question.beforeImage)
                self.afterImageView.image = UIImage(named: question.afterImage)
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
        
        correctAnswerCount.asObservable()
            .subscribeNext { [unowned self] count in
                switch count {
                case 0 ..< 3: self.message = "乙"
                case 3 ..< 6: self.message = "なかなか"
                case 6 ..< 9: self.message = "おしい"
                case 10: self.message = "完璧"
                default: self.message = "お疲れ"
                }
        }
        .addDisposableTo(disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
