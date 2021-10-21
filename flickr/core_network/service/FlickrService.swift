//
//  FlickrService.swift
//  flickr
//
//  Created by User on 10/21/21.
//

import Foundation

class FlickrService {
    
    private lazy var sessing: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = false
        return URLSession(configuration: config)
    }()
    
    func createRequest(absoluteURL: String, data: Data, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: URL(string: absoluteURL)!)
        request.httpMethod = method
        request.httpBody = data
        return request
    }
    
//    func makeRequest(path: String, method: String, params: [String: Any], completion: @escaping (Result<Data, Error>) -> Void) {
//        
//        let finalURL = EndpointApi.baseURLString + path
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
//                //                completion(.failure(ServerError.internalError))
//            }
//        }
//        
//        task.resume()
//    }
//    
//    
//    private func makeGet(path: String, params: [String: String?]) -> URLRequest{
//        let finalStringURL = hostURL + path
//        //        let url = URL(string: finalStringURL)!
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
//    
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
    
    func getProfileInfo(userId: String) {
        
    }
}
