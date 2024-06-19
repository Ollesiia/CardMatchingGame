//
//  UserDataService.swift
//  CardMatchingGame
//
//  Created by Олеся Скидан on 24.04.2024.
//

import Foundation

class UserDataService {
    static let shared = UserDataService()

    private let defaults = UserDefaults.standard
    
    private let userIDKey = K.WebView.userIDKey
    private let fullrefKey = K.WebView.fullrefKey
    
    private let appID = "f47ac10b-58cc-4372-a567-0e02b2c3d479"
    

    private init() {}

    func getUserID() -> String? {
        return defaults.string(forKey: userIDKey)
    }
    
    func setUserID(_ userID: String) {
        defaults.set(userID, forKey: userIDKey)
    }
    
    func getFullRef() -> String? {
        return defaults.string(forKey: fullrefKey)
    }
    
    func setFullRef(_ fullRef: String) {
        defaults.set(fullRef, forKey: fullrefKey)
    }
    
}
