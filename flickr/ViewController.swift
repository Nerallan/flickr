//
//  ViewController.swift
//  flickr
//
//  Created by User on 9/30/21.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let service = FlickrService()
        service.getRequestToken()
    }
    
    
}

