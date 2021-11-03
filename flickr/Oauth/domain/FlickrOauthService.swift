//
//  FlickrService.swift
//  flickr
//
//  Created by User on 9/30/21.
//

import Foundation;
import SafariServices

enum FlickrOauthError: Error {
    case parsing(description: String)
    case network(description: String)
}

class FlickrOauthService {
    
    var state: State?
    
    enum State {
        case tokenRequested
        case authorizeRequested((URL) -> Void)
        case accessTokenRequested
        case successfullyAuthentificated
    }

    private lazy var sessing: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = false
        return URLSession(configuration: config)
    }()
    
    private func makePostWithHeader(url: String, authHeader: String) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        return request
    }
    
    func authorize(viewController: UIViewController, completion: @escaping (Result<RequestAccessTokenResponse, Error>) -> Void) {
        guard state == nil else { return }
        
        getRequestToken { result in
            switch result {
            case .success(let requestTokenResponse):
                self.getUserAuthorization(viewController: viewController, requestTokenResponse: requestTokenResponse) { result in
                    switch result {
                    case .success(let url):
                        self.exchangeRequestToAccessToken(url: url, requestTokenResponse: requestTokenResponse, completion: completion)
                    case .failure(let error):
                        completion(.failure(error))
                        break
                    }
                }
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
    
    private func getRequestToken(completion: @escaping(Result<RequestOAuthTokenResponse, Error>) -> Void) {
        let helper = OauthHelper()
        let mapper = FlickrOauthMapper(oauthHelper: helper)
        let requestParams = mapper.mapToRequestTokenParams()
        
        // Once OAuth Signature is included in our parameters, build the authorization header
        let authHeader = helper.authorizationHeader(params: requestParams)
        let request = makePostWithHeader(url: FlickrOauthAPI.requestTokenURL, authHeader: authHeader)
        
        let task = sessing.resultDataTask(request: request) { result  in
        
            let requestOAuthTokenResponseResult = result.flatMap { data -> Result<RequestOAuthTokenResponse, Error> in
                
                guard let dataString = String(data: data, encoding: .utf8) else {
                    return .failure(FlickrOauthError.parsing(description: "error parsing"))
                }
                
                let attributes = dataString.urlQueryParameters
                
                return .success(.init(
                    oauthToken: attributes["oauth_token"] ?? "",
                    oauthTokenSecret: attributes["oauth_token_secret"] ?? "",
                    oauthCallbackConfirmed:  attributes["oauth_callback_confirmed"] ?? ""
                ))
            }
            completion(requestOAuthTokenResponseResult)
        }
        task.resume()
    }
    
    private func getUserAuthorization(viewController: UIViewController, requestTokenResponse: RequestOAuthTokenResponse, result: @escaping (Result<URL, Error>) -> Void) {
        let authorizeFinalURL = "\(FlickrOauthAPI.authorizeURL)?oauth_token=\(requestTokenResponse.oauthToken)&perms=write"
        guard let oauthUrl = URL(string: authorizeFinalURL) else { return }
        
        // PROCESS AUTHORIZATION in WebView
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        
        let safariViewController = SFSafariViewController(url: oauthUrl, configuration: config)
        
        DispatchQueue.main.async {
            viewController.present(safariViewController, animated: true)
        }
        state = .authorizeRequested({ (url) in
            safariViewController.dismiss(animated: true, completion: nil)
            result(.success(url))
        })

    }
    
    func redirectFromWebView(url: URL){
        // guard case let .authorizeRequested(handler) = state else { return }
        switch state {
        case .authorizeRequested(let handler):
            handler(url)
        default:
            break
        }
    }
    
    private func exchangeRequestToAccessToken(url: URL?, requestTokenResponse: RequestOAuthTokenResponse, completion: @escaping (Result<RequestAccessTokenResponse, Error>) -> Void) {
        guard let parameters = url?.query?.urlQueryParameters else { return }
        /*
         url => flickrsdk://success?oauth_token=XXXX&oauth_verifier=ZZZZ
         url.query => oauth_token=XXXX&oauth_verifier=ZZZZ
         url.query?.urlQueryStringParameters => ["oauth_token": "XXXX", "oauth_verifier": "YYYY"]
         */
        guard let verifier = parameters["oauth_verifier"] else { return }
        
        // Start Step 3: Request Access Token
        let accessTokenInput = RequestAccessTokenInput(
            consumerKey: FlickrOauthAPI.consumerKey,
            consumerSecret: FlickrOauthAPI.secretKey,
            requestToken: requestTokenResponse.oauthToken,
            requestTokenSecret: requestTokenResponse.oauthTokenSecret,
            oauthVerifier: verifier
        )
        requestAccessToken(args: accessTokenInput) { accessTokenResponse in
            // Process Completed Successfully!
            completion(accessTokenResponse)
        }
    }
    
    private func requestAccessToken(args: RequestAccessTokenInput,
                                    completion: @escaping (Result<RequestAccessTokenResponse, Error>) -> Void) {
        
        let helper = OauthHelper()
        let mapper = FlickrOauthMapper(oauthHelper: helper)
        let params = mapper.mapToAccessTokenParams(args: args, url: FlickrOauthAPI.accessTokenURL,  httpMethod: "POST")
        
        // Once OAuth Signature is included in our parameters, build the authorization header
        let authHeader = helper.authorizationHeader(params: params)
        let urlRequest = makePostWithHeader(url: FlickrOauthAPI.accessTokenURL, authHeader: authHeader)
        
        let task = sessing.resultDataTask(request: urlRequest) { result  in
            let requestAccessTokenResponse = result.flatMap { data -> Result<RequestAccessTokenResponse, Error> in
                
                guard let dataString = String(data: data, encoding: .utf8) else {
                    return .failure(FlickrOauthError.parsing(description: "error parsing"))
                }
                
                let attributes = dataString.urlQueryParameters
       
                return .success(.init(accessToken: attributes["oauth_token"] ?? "",
                                      accessTokenSecret: attributes["oauth_token_secret"] ?? "",
                                      userId: attributes["user_nsid"] ?? "",
                                      username: attributes["username"] ?? "",
                                      fullName: attributes["fullname"] ?? ""))
            
            }
            
            completion(requestAccessTokenResponse)
        }
        task.resume()
    }
    
    // output from 3d request
    struct RequestAccessTokenResponse {
        let accessToken: String
        let accessTokenSecret: String
        let userId: String
        let username: String
        let fullName: String
    }
    
    // output from 1st request
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
        self
            .split(separator: "&")
            .map { $0.split(separator: "=") }
            .filter{ $0.count == 2 }
            .forEach {
                let key = "\($0[0])"
                let val = "\($0[1])"
                params[key] = val
            }
        return params
    }
}
