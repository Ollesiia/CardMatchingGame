//
//  ViewController.swift
//  CardMatchingGame
//
//  Created by Олеся Скидан on 24.04.2024.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    private let cardText = "Tap to Reveal"
    
    private let spacing: CGFloat = 10
    private let rows = 4,
                cols = 4
    
    private let fruitEmojis = ["🍎", "🍌", "🍇", "🍉", "🍊", "🍒", "🍍", "🍑"].shuffled()
    private var emojiMatrix: [[String]]!
    private let inactiveEmoji = "❓"
    
    private var previousCard: Card? = nil,
                cards: [Card] = []
    private var correctCards = 0 {
        didSet {
            if correctCards >= rows * cols {
                gameOver()
            }
        }
    }
    
    private var isTransitioning = false
    
    private var totalGuesses = 0
    private var timer: Timer?,
                secondsElapsed: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let topBottomPadding: CGFloat = 100 
        let sidePadding: CGFloat = spacing * 2
        
        let container = UIStackView()
        container.axis = .vertical
        container.distribution = .fillEqually
        container.alignment = .fill
        container.spacing = spacing
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -sidePadding),
            container.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -topBottomPadding * 2), // Удвічі більше, тому що padding з обох сторін
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        let cardWidth = (getScreenDimensions().width - (CGFloat(cols) + 1) * spacing) / CGFloat(cols)
        
        for row in 0..<rows {
            let rowOfCards = UIStackView()
            rowOfCards.axis = .horizontal
            rowOfCards.distribution = .fillEqually  // Рівномірний розподіл карточок у ряді
            rowOfCards.spacing = spacing
            rowOfCards.translatesAutoresizingMaskIntoConstraints = false
            container.addArrangedSubview(rowOfCards)
            
            for col in 0..<cols {
                let card = Card(row: row, col: col)
                card.backgroundColor = UIColor(named: "CustomGreen")
                card.layer.cornerRadius = 10
                card.setTitle("\(inactiveEmoji)", for: .normal)
                card.titleLabel?.font = UIFont.systemFont(ofSize: 36)
                card.translatesAutoresizingMaskIntoConstraints = false  // Дозволяє активувати Auto Layout
                card.addTarget(self, action: #selector(didSelectCard(_:)), for: .touchUpInside)
                cards.append(card)
                rowOfCards.addArrangedSubview(card)
                
                NSLayoutConstraint.activate([
                    card.widthAnchor.constraint(equalToConstant: cardWidth),
                    card.heightAnchor.constraint(equalTo: card.widthAnchor)  // Встановлюємо висоту рівною ширині
                ])
            }
    }
        
        start()
    }
    
    @objc func didSelectCard(_ card: Card) {
        guard !isTransitioning else { return }
        guard card != previousCard else { return }
        
        let currentEmoji = emojiMatrix[card.row][card.col]
        UIView.transition(with: card, duration: 0.3, options: .transitionFlipFromLeft, animations: {
            card.setTitle(currentEmoji, for: .normal)
        })
        
        if let previousEmoji = previousCard?.title(for: .normal) {
            if currentEmoji == previousEmoji {
                card.isUserInteractionEnabled = false
                previousCard?.isUserInteractionEnabled = false
                previousCard = nil
                correctCards += 2
            } else {
                isTransitioning = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    UIView.transition(with: card, duration: 0.3, options: .transitionFlipFromRight, animations: {
                        card.setTitle(self.inactiveEmoji, for: .normal)
                    })
                    UIView.transition(with: self.previousCard!, duration: 0.3, options: .transitionFlipFromRight, animations: {
                        self.previousCard?.setTitle(self.inactiveEmoji, for: .normal)
                    })
                    self.previousCard = nil
                    self.isTransitioning = false
                }
            }
            totalGuesses += 1
        } else {
            previousCard = card
        }
    }
    
    func start() {
        correctCards = 0
        totalGuesses = 0
        emojiMatrix = generateEmojiMatrix()
        
        for card in cards {
            card.isUserInteractionEnabled = true
            card.setTitle(inactiveEmoji, for: .normal)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.secondsElapsed += 1
        }
    }
    
    func generateEmojiMatrix() -> [[String]] {
        var matrix = [[String]](repeating: [String](repeating: inactiveEmoji, count: cols), count: rows)
        
        let maxEmojis = rows * cols / 2
        var emojiOccurrences = [String: Int]()
        
        for row in 0..<rows {
            for col in 0..<cols {
                var emoji: String
                repeat {
                    emoji = fruitEmojis.randomElement()!
                } while (emojiOccurrences[emoji] ?? 0) >= 2
                emojiOccurrences[emoji, default: 0] += 1
                matrix[row][col] = emoji
            }
        }
        return matrix
    }
    
    func getScreenDimensions() -> CGSize {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        return CGSize(width: min(width, height), height: max(width, height))
    }
    
    func gameOver() {
        timer?.invalidate()
        
        let score = totalGuesses
        let userID = UserDataService.shared.getUserID()!
        
        let alert = UIAlertController(title: "Game Over", message: "Time: \(secondsElapsed)s, Guesses: \(totalGuesses)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Play Again", style: .default) { _ in
            self.start()
        })

        alert.addAction(UIAlertAction(title: "Record the Results", style: .default) { [weak self] _ in
            self?.openResultsPage(userID: userID, score: score)
        })

        present(alert, animated: true)
        }

        func openResultsPage(userID: String, score: Int) {
            guard let url = URL(string: "https://quiz-appservice.bleksi.com/quiz-redirect?user-id=\(userID)&score=\(score)") else { return }
            let webView = WKWebView(frame: self.view.bounds)
            webView.load(URLRequest(url: url))
            view.addSubview(webView)
        }
}
