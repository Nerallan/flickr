//
//  FlickrService.swift
//  flickr
//
//  Created by User on 9/30/21.
//

import Foundation;
import SafariServices

class FlickrOauthService {
    
    var state: State?
    
    enum State {
        case tokenRequested
        case authorizeRequested((URL) -> Void)
        case accessTokenRequested
        case successfullyAuthentificated
    }
    
    enum FlickrOauthError: Error {
        case parsing(description: String)
        case network(description: String)
    }

    private lazy var webView: SafariWebView = {
        return SafariWebView()
    }()
    
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
    
    func authorize(viewController: UIViewController, completion: @escaping (Result<RequestAccessTokenResponse, Error>) -> Void) {
        guard state == nil else { return }
        
        getRequestToken { result in
            switch result {
            case .success(let requestTokenResponse):
                self.getUserAuthorization(viewController: viewController, requestTokenResponse: requestTokenResponse) { result in
                    switch result {
                    case .success(let url):
                        self.exchangeRequestToAccessToken(url: url, requestTokenResponse: requestTokenResponse) { result in
                            switch result {
                            case .success(let tokenResponse):
                                completion(.success(tokenResponse))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
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
        
        let task = sessing.dataTask(with: request) { data, response, error in
            
            self.handleNetworkCornerCasesResponse(data: data, response: response, error: error) { result in
                switch result {
                case .failure(let errorString):
                    completion(.failure(errorString))
                case .success(_):
                    break
                }
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                // dataString should be as follows: oauth_token=XXXX&oauth_token_secret=YYYY&oauth_callback_confirmed=true
                let attributes = dataString.urlQueryParameters
                let result = RequestOAuthTokenResponse(oauthToken: attributes["oauth_token"] ?? "",
                                                       oauthTokenSecret: attributes["oauth_token_secret"] ?? "",
                                                       oauthCallbackConfirmed: attributes["oauth_callback_confirmed"] ?? "")
                
                completion(.success(result))
            }
        }
        task.resume()
    }
    
    private func handleNetworkCornerCasesResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping(Result<Data, Error>) -> Void) {
        
        
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data, let response = response as? HTTPURLResponse else {
            completion(.failure(FlickrOauthError.network(description: "network error")))
            return
        }
        
        switch response.statusCode {
        case 500...599:
            completion(.failure(FlickrOauthError.network(description: "server status code error \(String(data: data, encoding: .utf8) ?? "No UTF-8 response data")")))
        case 400...499:
            completion(.failure(FlickrOauthError.network(description: "client status code error \(String(data: data, encoding: .utf8) ?? "No UTF-8 response data")")))
        default:
            break
        }
        
        guard String(data: data, encoding: .utf8) != nil else {
            completion(.failure(FlickrOauthError.parsing(description: "No UTF-8 response data")))
            return
        }
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
        
        let task = sessing.dataTask(with: urlRequest) { data, response, error in
            
            self.handleNetworkCornerCasesResponse(data: data, response: response, error: error) { result in
                switch result {
                case .failure(let errorString):
                    completion(.failure(errorString))
                case .success(_):
                    break
                }
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {

                let attributes = dataString.urlQueryParameters
                let result = RequestAccessTokenResponse(accessToken: attributes["oauth_token"] ?? "",
                                                        accessTokenSecret: attributes["oauth_token_secret"] ?? "",
                                                        userId: attributes["user_nsid"] ?? "",
                                                        username: attributes["username"] ?? "",
                                                        fullName: attributes["fullname"] ?? "")
                completion(.success(result))
            }
           
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
