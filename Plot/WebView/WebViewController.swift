//
//  WebViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import WebKit

protocol EndedWebViewDelegate: class {
    func updateMXMembers()
}

class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    
    var webView: WKWebView!
    
    var urlString: String?
    
    var controllerTitle: String?
    
    weak var delegate : EndedWebViewDelegate?
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
                
        title = controllerTitle
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = doneBarButton
                
        if let url = urlString, let myURL = URL(string: url) {
            let myRequest = URLRequest(url: myURL)
            webView.load(myRequest)
            webView.allowsBackForwardNavigationGestures = true
        }

    }
    
    @IBAction func done(_ sender: AnyObject) {
        self.delegate?.updateMXMembers()
        self.dismiss(animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor
        navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        
        // Intercept custom URI
        let surl = navigationAction.request.url?.absoluteString
        if (surl?.hasPrefix("atrium://"))! {
            // Take action here
            print("atrium://")
            // Cancel request
            decisionHandler(.cancel)
            return
        }

        // Allow request
        decisionHandler(.allow)
    }
    
}
