//
//  Constants.swift
//  CardMatchingGame
//
//  Created by Олеся Скидан on 24.04.2024.
//

import Foundation

struct K {
    
    struct WebView {
        static let webViewRegistrationURL: String = "https://quiz-appservice.bleksi.com/quiz-auth"
        static let failedMessage: String = "Failed to process URL"
        static let userIDKey = "userID"
        static let fullrefKey = "fullref"
    }
    
    struct Messages {
        static let incorrect: String = "Incorrect URL"
        static let error: String = "Error"
        static let ok: String = "OK"
        static let pageLoadError: String = "Page load error"
        static let startAgain: String = "Start again"
        static let recordTheResult: String = "Record the result"
        static let earnedPoints = "Points earned"
        static let gameOver: String = "Game over!"
        static let yourTime: String = "Your time"
    }
}


