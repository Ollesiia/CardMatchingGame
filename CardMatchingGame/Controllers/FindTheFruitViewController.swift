//
//  FindTheFruitViewController.swift
//  CardMatchingGame
//
//  Created by Олеся Скидан on 25.04.2024.
//


import UIKit
import WebKit

class FindTheFruitViewController: UIViewController {
    override var prefersStatusBarHidden: Bool { return true }

    private let spacing: CGFloat = 10
    private let rows = 4, cols = 4
    private var fruitEmojis = ["🍎", "🍌", "🍇", "🍉", "🍊", "🍒", "🍍", "🍑"]
    private var emojiMatrix: [[String]]!
    private let inactiveEmoji = "❓"

    private var targetEmoji = ""
    private var attemptsLeft: Int = 0
    private var score = 0
    
    private var cards: [UIButton] = []
    
    private var timer: Timer?, secondsElapsed: Int = 0
    private var scoreLabel: UILabel!
    private var targetLabel: UILabel!
    private var timerLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupGame()
    }

    func setupGame() {
        fruitEmojis = fruitEmojis.shuffled()
        attemptsLeft = rows * cols / 2
        score = 0
        secondsElapsed = 0
        targetEmoji = fruitEmojis.randomElement()!
        emojiMatrix = generateEmojiMatrix()
        cleanUI()
        configureUI()
        startTimer()
    }

    func cleanUI() {
        cards.forEach { $0.removeFromSuperview() }
        cards.removeAll()
        targetLabel?.removeFromSuperview()
        scoreLabel?.removeFromSuperview()
        timerLabel?.removeFromSuperview()
    }

    func configureUI() {
        targetLabel = UILabel()
        targetLabel.text = "Find: \(targetEmoji)"
        targetLabel.textAlignment = .center
        targetLabel.font = UIFont.systemFont(ofSize: 24)
        targetLabel.frame = CGRect(x: 0, y: 100, width: view.bounds.width, height: 30) // Отступ сверху увеличен
        view.addSubview(targetLabel)
        
        scoreLabel = UILabel()
        scoreLabel.text = "Score: \(score)"
        scoreLabel.textAlignment = .center
        scoreLabel.font = UIFont.systemFont(ofSize: 24)
        scoreLabel.frame = CGRect(x: 0, y: view.bounds.height - 80, width: view.bounds.width, height: 30) // Отступ снизу увеличен
        view.addSubview(scoreLabel)
        
        timerLabel = UILabel()
        timerLabel.text = "Time: \(secondsElapsed)s"
        timerLabel.textAlignment = .center
        timerLabel.font = UIFont.systemFont(ofSize: 24)
        timerLabel.frame = CGRect(x: 0, y: 130, width: view.bounds.width, height: 30)
        view.addSubview(timerLabel)

        let gridWidth = view.bounds.width - (CGFloat(cols) + 1) * spacing
        let cardSize = (gridWidth / CGFloat(cols))
        
        let topPadding: CGFloat = 180 
        let bottomPadding: CGFloat = 100
        
        for row in 0..<rows {
            for col in 0..<cols {
                let card = UIButton(frame: CGRect(x: CGFloat(col) * (cardSize + spacing) + spacing,
                                                  y: CGFloat(row) * (cardSize + spacing) + topPadding,
                                                  width: cardSize,
                                                  height: cardSize))
                card.backgroundColor = UIColor(named: "CustomGreen")
                card.layer.cornerRadius = 10
                card.setTitle(inactiveEmoji, for: .normal)
                card.titleLabel?.font = UIFont.systemFont(ofSize: 36)
                card.addTarget(self, action: #selector(didSelectCard(_:)), for: .touchUpInside)
                view.addSubview(card)
                cards.append(card)
            }
        }
    }


    @objc func didSelectCard(_ sender: UIButton) {
        if attemptsLeft > 0 && sender.title(for: .normal) == inactiveEmoji {
            let cardIndex = cards.firstIndex(of: sender)!
            let row = cardIndex / cols
            let col = cardIndex % cols
            let currentEmoji = emojiMatrix[row][col]
            UIView.transition(with: sender, duration: 0.3, options: .transitionFlipFromLeft, animations: {
                sender.setTitle(currentEmoji, for: .normal)
            })
            
            if currentEmoji == targetEmoji {
                score += attemptsLeft
                sender.isUserInteractionEnabled = false
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    UIView.transition(with: sender, duration: 0.3, options: .transitionFlipFromRight, animations: {
                        sender.setTitle(self.inactiveEmoji, for: .normal)
                    })
                }
            }
            attemptsLeft -= 1
            updateUI()
            checkGameOver() // Проверяем, закончилась ли игра после каждого выбора
        }
    }
    

    func updateUI() {
        scoreLabel.text = "Score: \(score)"
        timerLabel.text = "Time: \(secondsElapsed)s"
    }

    func checkGameOver() {
        if attemptsLeft == 0 {
            timer?.invalidate()
            showGameOverAlert()
        }
    }

    func allTargetEmojisFound() -> Bool {
        for card in cards where card.title(for: .normal) == targetEmoji {
            if card.isUserInteractionEnabled {
                return false
            }
        }
        return true
    }

    func showGameOverAlert() {
            let alert = UIAlertController(title: "Game Over", message: "Score: \(score), Time: \(secondsElapsed)s", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Play Again", style: .default) { _ in
                self.setupGame()
            })

            alert.addAction(UIAlertAction(title: "Record the Results", style: .default) { [weak self] _ in
                self?.openResultsPage()
            })

            present(alert, animated: true)
        }

    func openResultsPage() {
            let userID = UserDataService.shared.getUserID()!
            let score = self.score
            if let url = URL(string: "https://quiz-appservice.bleksi.com/quiz-redirect?user-id=\(userID)&score=\(score)") {
                let webView = WKWebView(frame: self.view.bounds)
                webView.load(URLRequest(url: url))
                view.addSubview(webView)
            }
        }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.secondsElapsed += 1
            self?.updateUI()
        }
    }

    func generateEmojiMatrix() -> [[String]] {
        var matrix = [[String]](repeating: [String](repeating: inactiveEmoji, count: cols), count: rows)
        var placedEmojis = 0
        while placedEmojis < (rows * cols) {
            let randomRow = Int.random(in: 0..<rows)
            let randomCol = Int.random(in: 0..<cols)
            if matrix[randomRow][randomCol] == inactiveEmoji {
                matrix[randomRow][randomCol] = fruitEmojis.randomElement()!
                placedEmojis += 1
            }
        }
        return matrix
    }
}
