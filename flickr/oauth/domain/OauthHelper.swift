//
//  OauthHelper.swift
//  flickr
//
//  Created by User on 10/4/21.
//

import Foundation
import CommonCrypto

class OauthHelper {
    
    private func signatureKey(consumerSecret: String, oauthTokenSecret: String?) -> String {
        
        guard let oauthSecret = oauthTokenSecret?.urlEncoded
        else { return consumerSecret.urlEncoded+"&" }
        
        return consumerSecret.urlEncoded+"&"+oauthSecret
        
    }
    
    private func signatureParameterString(params: [String: String]) -> String {
        return params
            .map { $0.key.urlEncoded + "=" + $0.value.urlEncoded }
            .sorted()
            .joined(separator: "&")
    }

    // The base string is constructed by concatenating the HTTP verb, the request URL, and all request parameters sorted by name, using lexicograhpical byte value ordering, separated by an '&'.
    private func signatureBaseString(httpMethod: String, url: String,
                                     params: [String: String]) -> String {
        
        let parameterString = signatureParameterString(params: params)
        return httpMethod + "&" + url.urlEncoded + "&" + parameterString.urlEncoded
        
    }
    
    private func hmac_sha1(signingKey: String, signatureBase: String) -> String {
        // HMAC-SHA1 hashing algorithm returned as a base64 encoded string
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), signingKey, signingKey.count, signatureBase, signatureBase.count, &digest)
        let data = Data(digest)
        return data.base64EncodedString()
    }
    
    func oauthSignature(httpMethod: String = "POST",
                        url: String,
                        params: [String: String],
                        consumerSecret: String,
                        oauthTokenSecret: String? = nil) -> String {
        
        let signingKey = signatureKey(consumerSecret: consumerSecret, oauthTokenSecret: oauthTokenSecret)
        
        let signatureBase = signatureBaseString(httpMethod: httpMethod, url: url, params: params)
        
        let signature = hmac_sha1(signingKey: signingKey, signatureBase: signatureBase)
        
        return signature
        
    }
    
    func authorizationHeader(params: [String: String]) -> String {
        return "OAuth " + params
            .map { $0.key.urlEncoded + "=" + $0.value.urlEncoded }
            .sorted()
            .joined(separator: ", ")
     }
}


extension String {
    var urlEncoded: String {
        var charset: CharacterSet = .urlQueryAllowed
        charset.remove(charactersIn: "\n:#/?@!$&'()*+,;=")
        return self.addingPercentEncoding(withAllowedCharacters: charset)!
    }
}


