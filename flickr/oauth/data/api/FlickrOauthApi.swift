//
//  FlickrApi.swift
//  flickr
//
//  Created by User on 10/4/21.
//

import Foundation

struct FlickrOauthAPI {
    // urls
    static let baseURLString = "https://api.flickr.com/services/rest"
    static let requestTokenURL = "https://www.flickr.com/services/oauth/request_token"
    static let authorizeURL = "https://www.flickr.com/services/oauth/authorize"
    static let accessTokenURL = "https://www.flickr.com/services/oauth/access_token"
    
    // keys and tokens
//    static let consumerKey = ""
//    static let secretKey = ""
    static let consumerKey = ""
    static let secretKey = ""
//    static let consumerKey = ""
//    static let secretKey = ""
//    static let oauth_callback = "myflickr://by.nerallan.flickr"
    static let oauth_callback = "myflickr://"
}
