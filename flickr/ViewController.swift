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
        
        flickrOauthService?.authorize(viewController: self) { result in
            switch result {
            case .success(let result):
                print("AUTHORIZED")
                print(result)
                self.getProfileData(userId: result.userId.removingPercentEncoding!, apiKey: FlickrOauthAPI.consumerKey)
            case .failure(let error):
                print("ERROR")
                print(error)
            }
        }
    }
    
    func getProfileData(userId: String, apiKey: String) {
        let flickrService = FlickrService()
        let params = [
            "method": FlickrEndpointApi.getProfile.rawValue,
            "format": "json",
            "nojsoncallback": "1",
            "api_key": apiKey,
            "user_id": userId
        ]
        let request = flickrService.createGetURLRequest(
            url: FlickrEndpointApi.baseURLString,
            params: params
        )

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let serializer = ModelSerializer<Hey>(decoder: decoder)
        flickrService.makeRequest(request: request, serializer: serializer) { resultString in
            print("result string \(resultString)")
        }
    }
}


struct Hey: Decodable {
    let profile: Profile
}

struct Profile: Decodable {
    let id: String
    let nsid: String
    let showcaseSet: String
    let firstName: String
    let lastName: String
}

// CodingKeys
