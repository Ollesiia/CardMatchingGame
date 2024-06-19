//
//  WebViewController.swift
//  CardMatchingGame
//
//  Created by Олеся Скидан on 26.04.2024.
//

import UIKit
import WebKit

class WebViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
        webView.navigationDelegate = self
        view.backgroundColor = .gray
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupBackgroundViews()
    }
    
    private func setupBackgroundViews() {
        let statusBarHeight: CGFloat
        let extraPadding: CGFloat = 5

        if #available(iOS 13.0, *) {
            guard let windowScene = view.window?.windowScene else { return }
            statusBarHeight = windowScene.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusBarHeight = UIApplication.shared.statusBarFrame.height
        }

        let statusBarBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: statusBarHeight + extraPadding))
        statusBarBackgroundView.backgroundColor = UIColor.clear
        statusBarBackgroundView.tag = 101
        view.addSubview(statusBarBackgroundView)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        webView.frame = view.bounds
        if let statusBarView = view.viewWithTag(101) {
            statusBarView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: statusBarView.frame.height)
        }
    }
    
    func configureWebView() {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        
        var urlString = K.WebView.webViewRegistrationURL
        
        if let fullref = UserDataService.shared.getFullRef() {
            urlString += "?fullref=\(fullref)"
        }
        
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        } else {
            showError(message: K.Messages.incorrect)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }
    
    private func processWebViewURL(_ url: URL?) {
        guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            showError(message: K.WebView.failedMessage)
            return
        }
        
        if let fullref = components.queryItems?.first(where: { $0.name == "fullref" })?.value, !fullref.isEmpty {
            UserDataService.shared.setFullRef(fullref)
        }
        
        if let userID = components.queryItems?.first(where: { $0.name == "user-id" })?.value {
            UserDataService.shared.setUserID(userID)
            showGameScreen()
        }
    }
    
    private func showGameScreen() {
        if let mainViewController = storyboard?.instantiateViewController(withIdentifier: "StartGameViewController") as? StartGameViewController {
            mainViewController.modalPresentationStyle = .fullScreen
            present(mainViewController, animated: true)
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: K.Messages.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:  K.Messages.ok, style: .default))
        present(alert, animated: true)
    }
}


extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()

        let javascript = "window.getComputedStyle(document.body).backgroundColor;"
        webView.evaluateJavaScript(javascript) { [weak self] result, error in
            guard let self = self else { return }
            
            if let bgColor = result as? String {
                self.updateStatusBarColor(bgColor)
            } else {
                print("Error fetching background color early: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        showError(message: "\(K.Messages.pageLoadError): \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true

        let javascript = """
        var header = document.querySelector('header');
        var style = window.getComputedStyle(header);
        var backgroundColor = style.backgroundColor;
        backgroundColor;
        """

        webView.evaluateJavaScript(javascript) { [weak self] result, error in
            guard let self = self else { return }
            
            if let bgColor = result as? String {
                print("Background color fetched: \(bgColor)")
                self.updateStatusBarColor(bgColor)
            } else {
                print("Error fetching background color: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        processWebViewURL(webView.url)
    }

    
    func updateStatusBarColor(_ cssColor: String?) {
        // Пытаемся преобразовать строку CSS в UIColor
        let parsedColor = UIColor(cssString: cssColor ?? "")

        // Определите цвет по умолчанию: используйте цвет из ассетов или серый
        let defaultColor = UIColor(named: "statusBarColor") ?? UIColor.gray

        // Проверка на полностью прозрачный цвет
        let finalColor = parsedColor?.cgColor.alpha == 0 ? defaultColor : parsedColor

        DispatchQueue.main.async {
            if let statusBarView = self.view.viewWithTag(101) {
                statusBarView.backgroundColor = finalColor ?? defaultColor
                print("Status bar color updated to: \(String(describing: finalColor))")
            } else {
                print("Failed to update status bar color: status bar view not found")
            }
        }
    }
}

extension UIColor {
    convenience init?(cssString: String) {
        let components = cssString
            .trimmingCharacters(in: CharacterSet(charactersIn: "rgba() "))
            .components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        guard components.count == 3 || components.count == 4,
              let red = Float(components[0]),
              let green = Float(components[1]),
              let blue = Float(components[2]),
              let alpha = components.count == 4 ? Float(components[3]) : 1.0,
              alpha != 0 else {
            return nil
        }

        self.init(red: CGFloat(red / 255.0), green: CGFloat(green / 255.0), blue: CGFloat(blue / 255.0), alpha: CGFloat(alpha))
    }
}
