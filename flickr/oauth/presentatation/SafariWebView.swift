//
//  SafariWebView.swift
//  flickr
//
//  Created by User on 10/15/21.
//

import Foundation
import SafariServices

class SafariWebView {
    
    func showSafariView(viewController: UIViewController, oauthURL: URL) {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        
        let safariViewController = SFSafariViewController(url: oauthURL, configuration: config)
        
        DispatchQueue.main.async {
            viewController.present(safariViewController, animated: true)
        }
    }
    
    func closeSafariView(viewController: UIViewController) {
        viewController.navigationController?.popViewController(animated: true)
        viewController.dismiss(animated: true, completion: nil)
    }
}
