//
//  AboutViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 24/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import UIKit
import WebKit

class AboutViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        //Add the Webview
        self.webView = WKWebView(frame: self.view.frame)
        let htmlPath = Bundle.main.path(forResource: "about", ofType: "html")
        let htmlUrl = URL(fileURLWithPath: htmlPath!)
        webView.navigationDelegate = self
        webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
        view = webView
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
                UIApplication.shared.open(navigationAction.request.url!)
                decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
