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
    static let consumerKey = "78d5f96b0bfe0a957f13b8f8cd237cca"
    static let secretKey = "7c7a2a2a595106af"
    static let oauth_callback = "myflickr://"
}
