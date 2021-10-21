//
//  FlickrOauthMapper.swift
//  flickr
//
//  Created by User on 10/15/21.
//

import Foundation

class FlickrOauthMapper {
    
    var helper: OauthHelper
    
    init(oauthHelper: OauthHelper) {
        helper = oauthHelper
    }
    
    func mapToRequestTokenParams() -> [String : String]  {
        var params = [String : String]()
        params["oauth_nonce"] = UUID().uuidString
        params["oauth_timestamp"] = String(Int(NSDate().timeIntervalSince1970))
        params["oauth_consumer_key"] = FlickrOauthAPI.consumerKey
        params["oauth_signature_method"] = "HMAC-SHA1"
        params["oauth_version"] = "1.0"
        params["oauth_callback"] = FlickrOauthAPI.oauth_callback // "myflickr://by.nerallan.flickr"
        params["oauth_signature"] = helper.oauthSignature(
            httpMethod: "POST",
            url: FlickrOauthAPI.requestTokenURL,
            params: params,
            consumerSecret: FlickrOauthAPI.secretKey
        )
        return params
    }
    
    func mapToAccessTokenParams(args: RequestAccessTokenInput, url: String, httpMethod: String) -> [String : String]  {
        var params: [String: String] = [
            "oauth_token" : args.requestToken,
            "oauth_verifier" : args.oauthVerifier,
            "oauth_consumer_key" : args.consumerKey,
            "oauth_nonce" : UUID().uuidString,
            "oauth_signature_method" : "HMAC-SHA1",
            "oauth_timestamp" : String(Int(NSDate().timeIntervalSince1970)),
            "oauth_version" : "1.0"
        ]
        // Build the OAuth Signature from Parameters
        params["oauth_signature"] = helper.oauthSignature(httpMethod: httpMethod,
                                                               url: url,
                                                               params: params, consumerSecret: args.consumerSecret,
                                                               oauthTokenSecret: args.requestTokenSecret)
        return params
    }
}
