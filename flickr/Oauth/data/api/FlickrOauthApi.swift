//
//  FlickrApi.swift
//  flickr
//
//  Created by User on 10/4/21.
//

import Foundation

struct FlickrOauthAPI {
    // urls
    static let requestTokenURL = "https://www.flickr.com/services/oauth/request_token"
    static let authorizeURL = "https://www.flickr.com/services/oauth/authorize"
    static let accessTokenURL = "https://www.flickr.com/services/oauth/access_token"
    
    // keys and tokens
    static let consumerKey = "b4a1c850c53148c94f76212304de062e"
    static let secretKey = "59a42bfedf391e92"
    static let oauth_callback = "myflickr://"
}
