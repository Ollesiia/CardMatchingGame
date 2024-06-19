//
//  StartGameViewController.swift
//  CardMatchingGame
//
//  Created by Олеся Скидан on 26.04.2024.
//

import UIKit

class StartGameViewController: UIViewController {
    @IBOutlet weak var startGameButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        if let mainViewController = storyboard?.instantiateViewController(withIdentifier: "ChooseGameViewController") as? ChooseGameViewController {
            mainViewController.modalPresentationStyle = .fullScreen
            present(mainViewController, animated: true)
        }

    }
    
}
