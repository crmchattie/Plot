//
//  WebViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/7/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import WebKit

protocol EndedWebViewDelegate: AnyObject {
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
    
    override func loadView() {
        let webPreferences = WKPreferences()
        webPreferences.javaScriptCanOpenWindowsAutomatically = true

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences = webPreferences

        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.isOpaque = false
        webView.backgroundColor = ThemeManager.currentTheme().launchBackgroundColor
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        
        title = controllerTitle
        navigationController?.navigationBar.barTintColor = ThemeManager.currentTheme().launchBackgroundColor

        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = doneBarButton
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()

        if let url = urlString, let myURL = URL(string: url) {
            let myRequest = URLRequest(url: myURL)
            webView.load(myRequest)
            webView.allowsBackForwardNavigationGestures = true
            activityIndicatorView.stopAnimating()
        } else {
            fetchData()
        }
        
    }
    
    func fetchData() {
        Service.shared.fetchMXConnectURL(current_member_guid: current_member_guid) { (search, err) in
            if let search = search, let url = search["url"], let myURL = URL(string: url) {
                DispatchQueue.main.async {
                    activityIndicatorView.stopAnimating()
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
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

    }
    
    /**
     Handle all navigation events from the webview. Cancel all postmessages from
     MX as they are not valid urls.
     See the post message documentation for more details:
     https://atrium.mx.com/docs#postmessage-events
     https://docs.mx.com/api#connect_postmessage_events
     */
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString
        let isPostMessageFromMX = url?.hasPrefix(appScheme) == true
                                  || url?.hasPrefix(atriumScheme) == true
                                  || url?.hasPrefix(mxScheme) == true

        if (isPostMessageFromMX) {
            let urlc = URLComponents(string: url ?? "")
            let path = urlc?.path ?? ""
            // there is only one query param ("metadata") with each url, so just grab the first
            let metaDataQueryItem = urlc?.queryItems?.first

            if path == "/oauthRequested" {
                handleOauthRedirect(payload: metaDataQueryItem)
            }

            decisionHandler(.cancel)
            return
        }

        // Make sure to open links in the user agent, not the webview.
        // Allowing a navigation action could navigate the user away from
        // connect and lose their session.
        if let urlToOpen = url {
            // Don't open the url, if it is the widget url itself on the first load
            if (urlToOpen != urlString) {
//                UIApplication.shared.open(URL(string: urlToOpen)!)
            }
        }

        decisionHandler(.allow)
    }

    /**
     Sometimes the widget will make calls to `window.open` these calls will end up here if
     `javaScriptCanOpenWindowsAutomatically` is set to `true`. When doing this, make sure
     to return `nil` here so you don't end up overwriting the widget webview instance. Generally speaking
     it is best to open the url in a new browser session.
     */
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let url = navigationAction.request.url?.absoluteString

        print("************************************", url ?? "")

        if let urlToOpen = url {
            // Don't open the url, if it is the widget url itself on the first load
            if (urlToOpen != urlString) {
                UIApplication.shared.open(URL(string: urlToOpen)!)
            }
        }

        return nil
    }

    /**
     Helpful methods for debugging webview failures.
     */
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failed during navigation!", error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Failed to load webview content!", error)
    }

    /**
     Handle the oauthRequested event. Parse out the oauth url from the event and open safari to that url
     NOTE: This code is somewhat optimistic, you'll want to add error handling that makes sense for your app.
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
    
}
