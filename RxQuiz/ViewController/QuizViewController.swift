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
import Social

final class QuizViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
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
        "zip",
        "take(2)",
        "takeLast(1)",
        "sample",
        "scan",
        "combineLatest",
        "concat",
        "map(x => 10 * x)",
        "startWith(1)",
        "reduce((x, y) => x + y",
        "combineLatest(a, b)",
        "retry(2)",
        "toArray",
        "a.takeWhileWithIndex { e, i in i < 4 }",
        "a.debounce(100, scheduler: s)",
        "a.delaySubscription(150, scheduler: s)",
        "a.takeWhile { $0 < 4 }",
        "a.takeUntil(b)",
        "a.skipUntil(b)",
        "a.skipWhile { $0 < 4 }",
        "a.filter { $0 > 10 }",
        "Observable.of(a).switchLatest()",
        "a.distinctUntilChanged()",
        "a.sample(b)",
        "a.throttle(100, scheduler: s)",
        "a.amb(b)",
        "a.single()",
        "ignoreElements",
        "Observable.of(a, b).merge()",
        "a.withLatestFrom(b)",
        "a.elementAt(2)",
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
        Observable<Int>.timer(RxTimeInterval(0), period: RxTimeInterval(0.1), scheduler: MainScheduler.instance)
            .filter { [unowned self] _ in
                self.currentQuestionIndex.value != self.questions.value.endIndex
            }
            .subscribeNext { [unowned self] _ in
                let time = -self.startDate.timeIntervalSinceNow
                let minutes = Int(time / 60)
                let seconds = Int(time % 60)
                let tenthsOfSecond = Int(time * 10 % 10)
                self.timeLabel.text = String(format: "%02d:%02d.%d",
                    minutes, seconds, tenthsOfSecond)
            }
            .addDisposableTo(disposeBag)
        
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
        
        questions.asDriver()
            .filter { $0.isEmpty }
            .driveNext { [unowned self] _ in
                let questions: [Question] = (JSONFromFile("Quiz")?["questions"].flatMap(decode))!
                questions.shuffle().toObservable()
                    .take(10)
                    .subscribeNext {
                        self.questions.value.append($0)
                    }
                    .addDisposableTo(self.disposeBag)
            }
            .addDisposableTo(disposeBag)
        
        buttons.forEach { button in
            button.rx_tap.asDriver()
                .driveNext { [unowned self] in
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
        
        currentQuestionIndex.asDriver()
            .driveNext { [unowned self] count in
                switch count {
                case self.questions.value.endIndex:
                    func restart() {
                        self.questions.value.removeAll()
                        self.currentQuestionIndex.value = 0
                        self.correctAnswerCount.value = 0
                        self.startDate = NSDate()
                    }
                    
                    let alertController = UIAlertController(
                        title: "10問中\(self.correctAnswerCount.value)問正解",
                        message: "\(self.timeLabel!.text!)秒\n\(self.message)",
                        preferredStyle: .Alert
                    )
                    
                    let okAction = UIAlertAction(title: "もう一度", style: .Default) { _ in
                        restart()
                    }
                    
                    let shareAction = UIAlertAction(title: "Twitterでシェアする", style: .Default) { [unowned self] _ in
                        let composeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
                        composeViewController.completionHandler = { _ in
                            restart()
                        }
                        composeViewController.setInitialText("10問中\(self.correctAnswerCount.value)問正解\n\(self.timeLabel!.text!)秒\n\(self.message)\n#Rx検定")
                        self.presentViewController(composeViewController, animated: true, completion: nil)
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
        
        currentQuestion.asDriver()
            .skip(1)
            .driveNext { [unowned self] question in
                self.beforeImageView.image = UIImage(named: question.beforeImage)
                self.afterImageView.image = UIImage(named: question.afterImage)
            }
            .addDisposableTo(disposeBag)
        
        currentAnswer.asDriver()
            .driveNext { [unowned self] answer in
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
                case 0 ..< 3: self.message = "Rx素人です"
                case 3 ..< 6: self.message = "Rxエセエバンジェリストです"
                case 6 ..< 10: self.message = "Rxエバンジェリストまであと一歩！"
                case 10: self.message = "おめでとう！あなたはRxエバンジェリストです！"
                default: self.message = "凡夫"
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
