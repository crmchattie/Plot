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
    
    var current_member_guid: String?
    
    let appScheme = "appscheme://"
    let mxScheme = "mx://"
    let atriumScheme = "atrium://"
    
    let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        return spinner
    }()
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
        } else {
            fetchData()
        }
        
    }
    
    func fetchData() {
        Service.shared.fetchMXConnectURL(current_member_guid: current_member_guid) { (search, err) in
            if let search = search, let url = search["url"], let myURL = URL(string: url) {
                DispatchQueue.main.async {
                    let myRequest = URLRequest(url: myURL)
                    self.webView.load(myRequest)
                    self.webView.allowsBackForwardNavigationGestures = true
                }
            }
        }
    }
    
    @IBAction func done(_ sender: AnyObject) {
        self.delegate?.updateMXMembers()
        self.dismiss(animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        
        // Ensure you are looking for schemes from both 'mx', 'atrium', and whatever you configured
        // ui_message_webview_url_scheme to be. In this example, it was 'appscheme'.
        let url = navigationAction.request.url?.absoluteString
        let isFromMX = url?.hasPrefix(appScheme) == true || url?.hasPrefix(mxScheme) == true || url?.hasPrefix(atriumScheme) == true
        
        if isFromMX {
            let urlc = URLComponents(string: url ?? "")
            let path = urlc?.path ?? ""
            // there is only one query parameter ("metadata")
            // so just grab the first one
            let metaDataQueryItem = urlc?.queryItems?.first
            
            if path == "/oauthRequested" {
                handleOauthRedirect(payload: metaDataQueryItem)
            }
            
            // Cancel request
            decisionHandler(.cancel)
            return
        }
        
        // Allow request
        decisionHandler(.allow)
    }
    
    /*
     * Handle the oauthRequested event. Parse out the OAuth URL from the event
     * and open Safari to that URL
     * NOTE: This code is somewhat optimistic, you'll want to add error handling
     * that makes sense for your app.
     */
    func handleOauthRedirect(payload: URLQueryItem?) {
        let metadataString = payload?.value ?? ""
        
        do {
            if let json = try JSONSerialization.jsonObject(with: Data(metadataString.utf8), options: []) as? [String: Any] {
                if let url = json["url"] as? String {
                    // open safari with the url from the json payload
                    UIApplication.shared.open(URL(string: url)!)
                }
            }
        } catch let error as NSError {
            print("Failed to parse payload: \(error.localizedDescription)")
        }
    }
    
    // Helpful methods for debugging errors
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failed during navigation!", error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Failed to load webview content!", error)
    }
    
}
