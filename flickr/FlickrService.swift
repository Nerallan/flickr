//
//  FlickrService.swift
//  flickr
//
//  Created by User on 9/30/21.
//

import Foundation;
import SafariServices

class FlickrService {
    
//    private let hostURL = "https://www.flickr.com"
    
    private lazy var sessing: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = false
        return URLSession(configuration: config)
    }()
    
//    func createRequest(absoluteURL: String, data: Data, method: String = "GET") -> URLRequest {
//        var request = URLRequest(url: URL(string: absoluteURL)!)
//        request.httpMethod = method
//        request.httpBody = data
//        return request
//    }
    
//    func makeRequest(path: String, method: String, params: [String: Any], completion: @escaping (Result<Data, Error>) -> Void) {
//
//        let finalURL = hostURL + path
//        var request = URLRequest(url: URL(string: finalURL)!)
//        request.httpMethod = method
//        request.httpBody = params
//        let request: URLRequest
//        do {
//            let data = try JSONSerialization.data(withJSONObject: params)
//
//            request = createRequest(absoluteURL: finalURL, data: data, method: method)
//        } catch {
//            return
//        }
//
//        let task = sessing.dataTask(with: request) { data, response, error in
//            if let data = data {
//                completion(.success(data))
//            } else if let error = error {
//                completion(.failure(error))
//            } else {
////                completion(.failure(ServerError.internalError))
//            }
//        }
//
//        task.resume()
//    }
    
    
//    private func makeGet(path: String, params: [String: String?]) -> URLRequest{
//        let finalStringURL = hostURL + path
////        let url = URL(string: finalStringURL)!
//        if var components = URLComponents(string: finalStringURL) {
//            var localVariable = components
//            components.queryItems = params.map { (key, value) in
//                URLQueryItem(name: key, value: value)
//            }
//
//            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
//            var request = URLRequest(url: (components.url!)!)
//            request.httpMethod = "GET"
//            return request
//        }
//    }
    
//    private func makePost(path: String, rawData: Any) -> URLRequest {
//        let finalStringURL = hostURL + path
//        var data: Data
//        do {
//            data = try JSONSerialization.data(withJSONObject: rawData)
//        } catch {
//            data = Data()
//        }
//        var request = URLRequest(url: URL(string: finalStringURL)!)
//        request.httpMethod = "POST"
//        request.httpBody = data
//        return request
//    }
    
    private func makePostWithHeader(url: String, authHeader: String) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        return request
    }

    
    private func makeRequest(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        let task = sessing.dataTask(with: request) { data, response, error in
            if let data = data {
                print("DATA")
                print(data)
                completion(.success(data))
                print("RESPONCE")
                print(response!)
            } else if let error = error {
                
                completion(.failure(error))
            } else {
//                completion(.failure(ServerError.internalError))
            }
        }
        
        task.resume()
    }
    
    private func getRequestTokenParams(helper: OauthHelper) -> [String : Any] {
        var params = [String : Any]()
        params["oauth_nonce"] = UUID().uuidString
        params["oauth_timestamp"] = String(Int(NSDate().timeIntervalSince1970))
        params["oauth_consumer_key"] = FlickrAPI.consumerKey // с портала
        params["oauth_signature_method"] = "HMAC-SHA1"
        params["oauth_version"] = "1.0"
        params["oauth_callback"] = FlickrAPI.oauth_callback
        params["oauth_signature"] = helper.oauthSignature(
            httpMethod: "POST",
            url: FlickrAPI.requestTokenURL,
            params: params,
            consumerSecret: FlickrAPI.secretKey
        )
        print("PARAMS")
        print(params)
        return params
    }
    
    private func getRequestToken(_ complete: @escaping(RequestOAuthTokenResponse) -> Unit) {
        
        let helper = OauthHelper()
        // вычисляется
        let requestParams = getRequestTokenParams(helper: helper)
      
//        Once OAuth Signature is included in our parameters, build the authorization header
        let authHeader = helper.authorizationHeader(params: requestParams)
        let request = makePostWithHeader(url: FlickrAPI.requestTokenURL, authHeader: authHeader)
        
        let task = sessing.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            guard let dataString = String(data: data, encoding: .utf8) else { return }
            // dataString should be as follows: oauth_token=XXXX&oauth_token_secret=YYYY&oauth_callback_confirmed=true
            let attributes = dataString.urlQueryParameters
            let result = RequestOAuthTokenResponse(oauthToken: attributes["oauth_token"] ?? "",
                                                   oauthTokenSecret: attributes["oauth_token_secret"] ?? "",
                                                   oauthCallbackConfirmed: attributes["oauth_callback_confirmed"] ?? "")
            
            print("=======================")
            print("RESULT \(result)")
            complete(result)
        }
        task.resume()
    }
    
    private func getUserAuthorization(requestTokenResponse: RequestOAuthTokenResponse) {
        let authorizeFinalURL = "\(FlickrAPI.authorizeURL)?oauth_token=\(requestTokenResponse.oauthToken)&perms=write"
        guard let oauthUrl = URL(string: authorizeFinalURL) else { return }
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        guard let url = request.url, navigationType == .linkClicked else { return true }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return false
    }
    
    private func exchangeRequestToAccessToken(url: URL, requestTokenResponse: RequestOAuthTokenResponse) {
        guard let parameters = url.query?.urlQueryParameters else { return }
        /*
         url => flickrsdk://success?oauth_token=XXXX&oauth_verifier=ZZZZ
         url.query => oauth_token=XXXX&oauth_verifier=ZZZZ
         url.query?.urlQueryStringParameters => ["oauth_token": "XXXX", "oauth_verifier": "YYYY"]
         */
        guard let verifier = parameters["oauth_verifier"] else { return }
        
        // Start Step 3: Request Access Token
        let accessTokenInput = RequestAccessTokenInput(
            consumerKey: FlickrAPI.consumerKey,
            consumerSecret: FlickrAPI.secretKey,
            requestToken: requestTokenResponse.oauthToken,
            requestTokenSecret: requestTokenResponse.oauthTokenSecret,
            oauthVerifier: verifier
        )
        requestAccessToken(args: accessTokenInput) { accessTokenResponse in
            // Process Completed Successfully!
            
        }
    }
    
    func requestAccessToken(args: RequestAccessTokenInput,
                               _ complete: @escaping (RequestAccessTokenResponse) -> Void) {
           let request = (url: FlickrAPI.accessTokenURL, httpMethod: "POST")
           
           var params: [String: Any] = [
               "oauth_token" : args.requestToken,
               "oauth_verifier" : args.oauthVerifier,
               "oauth_consumer_key" : args.consumerKey,
               "oauth_nonce" : UUID().uuidString,
               "oauth_signature_method" : "HMAC-SHA1",
               "oauth_timestamp" : String(Int(NSDate().timeIntervalSince1970)),
               "oauth_version" : "1.0"
           ]
           
            let oauthHelper = OauthHelper()
        
           // Build the OAuth Signature from Parameters
        params["oauth_signature"] = oauthHelper.oauthSignature(httpMethod: request.httpMethod,
                                                      url: request.url,
                                                      params: params, consumerSecret: args.consumerSecret,
                                                      oauthTokenSecret: args.requestTokenSecret)
           
           // Once OAuth Signature is included in our parameters, build the authorization header
        let authHeader = oauthHelper.authorizationHeader(params: params)
           
           guard let url = URL(string: request.url) else { return }
           var urlRequest = URLRequest(url: url)
           urlRequest.httpMethod = request.httpMethod
           urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
           let task = sessing.dataTask(with: urlRequest) { data, response, error in
               guard let data = data else { return }
               guard let dataString = String(data: data, encoding: .utf8) else { return }
               let attributes = dataString.urlQueryParameters
               let result = RequestAccessTokenResponse(accessToken: attributes["oauth_token"] ?? "",
                                                       accessTokenSecret: attributes["oauth_token_secret"] ?? "",
                                                       userId: attributes["user_nsid"] ?? "",
                                                       screenName: attributes["username"] ?? "")
               complete(result)
           }
           task.resume()
       }
    
    func authorize() {
        getRequestToken() { requestTokenResponse in
            getUserAuthorization(requestTokenResponse: requestTokenResponse)
            requestTokenResponse.oauthToken
        }
    }
    
    // инпут на 3й запрос
    struct RequestAccessTokenInput {
           let consumerKey: String
           let consumerSecret: String
           let requestToken: String // = RequestOAuthTokenResponse.oauthToken
           let requestTokenSecret: String // = RequestOAuthTokenResponse.oauthTokenSecret
           let oauthVerifier: String
    }
    
    // аутпут на 3й запрос
    struct RequestAccessTokenResponse {
        let accessToken: String
        let accessTokenSecret: String
        let userId: String
        let screenName: String
    }
    
    // аутпут на 1й запрос
    struct RequestOAuthTokenResponse {
        let oauthToken: String
        let oauthTokenSecret: String
        let oauthCallbackConfirmed: String
    }
    
    struct FlickrOAuthClientInput {
           let consumerKey: String
           let consumerSecret: String
           let accessToken: String
           let accessTokenSecret: String
       }
}

extension String {
    var urlQueryParameters: Dictionary<String, String> {
        // breaks apart query string into a dictionary of values
        var params = [String: String]()
        let items = self.split(separator: "&")
        for item in items {
            let combo = item.split(separator: "=")
            if combo.count == 2 {
                let key = "\(combo[0])"
                let val = "\(combo[1])"
                params[key] = val
            }
        }
        return params
    }
}
