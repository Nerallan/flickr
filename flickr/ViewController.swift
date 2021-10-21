//
//  ViewController.swift
//  flickr
//
//  Created by User on 9/30/21.
//

import UIKit

class ViewController: UIViewController {

    var flickrOauthService: FlickrOauthService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        flickrOauthService?.authorize(viewController: self) { result in
            switch result {
            case .success(let accessToken):
                print("AUTHORIZED")
                print(accessToken)
            case .failure(let error):
                print("ERROR")
                print(error)
            }
        }
    }
}

