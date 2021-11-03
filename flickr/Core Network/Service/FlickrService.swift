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
    
//    private func makeRequest(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
//        let task = sessing.dataTask(with: request) { data, response, error in
//            if let data = data {
//                print("DATA")
//                print(data)
//                completion(.success(data))
//                print("RESPONCE")
//                print(response!)
//            } else if let error = error {
//                completion(.failure(error))
//            } else {
//                //                completion(.failure(ServerError.internalError))
//            }
//        }
//        task.resume()
//    }
    
    
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
    private func makePostWithHeader(url: String) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
//        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        return request
    }
    
    func createGetURLRequest(url: String, params: [String: String?]) -> URLRequest {
        var urlComponents = URLComponents(string: url)!

        urlComponents.queryItems = params.map { (key, value) in
            URLQueryItem(name: key.urlEncoded, value: value)
        }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        return request
    }

    func makeRequest<Serializer : SerializerProtocol>(request: URLRequest, serializer: Serializer, completion: @escaping(Result<Serializer.T, Error>) -> Void) {
        let task = sessing.resultDataTask(request: request) { result  in
            
            let resultString = result.flatMap { data -> Result<Serializer.T, Error> in
                if let dataString = String(data: data, encoding: .utf8) {
//                    return .failure(FlickrOauthError.parsing(description: "error parsing"))
                    print(dataString)
                }
                do {
                    let result = try serializer.serialize(data: data)
                    return .success(result)
                } catch {
                    return .failure(error)
                }
            }
            completion(resultString)
        }
        task.resume()
    }
    
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
}


extension URLSession {
    func resultDataTask(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionDataTask {
        dataTask(with: request) { data, response, error in
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
                completion(.success(data))
            }
        }
    }
}


protocol SerializerProtocol {
    associatedtype T
    func serialize(data: Data) throws -> T
}


struct ModelSerializer<T: Decodable>: SerializerProtocol {

    let decoder: JSONDecoder
    
    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    func serialize(data: Data) throws -> T {
        let result = try decoder.decode(T.self, from: data)
        return result
    }
}

struct VoidSerializer: SerializerProtocol {
        
    func serialize(data: Data) throws {
        
    }
}
