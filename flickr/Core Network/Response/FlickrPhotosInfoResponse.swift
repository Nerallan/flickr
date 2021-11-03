//
//  FlickrPhotosInfoResponse.swift
//  flickr
//
//  Created by User on 10/21/21.
//

import Foundation

struct FlickrPhotosInfoResponse: Codable {
    let photosInfo: FlickrPhotosResponse
    
    enum CodingKeys: String, CodingKey {
        case photosInfo = "photos"
    }
}
