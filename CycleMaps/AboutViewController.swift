//
//  AboutViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 24/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class AboutViewController : UIViewController, UIWebViewDelegate {
    var webView: UIWebView?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "About"
        
        //Add the Webview
        self.webView = UIWebView(frame: self.view.frame)
        self.webView?.delegate = self
        let path = Bundle.main.path(forResource: "about", ofType: "html")
        let text = try? String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        
        webView?.loadHTMLString(text!, baseURL: nil)
        self.view.addSubview(webView!)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            UIApplication.shared.open(request.url!)
            return false
        }
        return true
    }
    
    func closeViewController() {
        self.dismiss(animated: true, completion: { () -> Void in
        })
    }
}
