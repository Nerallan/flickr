//
//  RequestAccessTokenInput.swift
//  flickr
//
//  Created by User on 10/17/21.
//

import Foundation

// input to 3d request
public struct RequestAccessTokenInput {
    let consumerKey: String
    let consumerSecret: String
    let requestToken: String // = RequestOAuthTokenResponse.oauthToken
    let requestTokenSecret: String // = RequestOAuthTokenResponse.oauthTokenSecret
    let oauthVerifier: String
}
