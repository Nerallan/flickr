//
//  EndpointApi.swift
//  flickr
//
//  Created by User on 10/13/21.
//

import Foundation

enum EndpointApi: String  {
    case getProfile = "flickr.profile.getProfile"
    case getHotList = "flickr.tags.getHotList"
    case getRecent = "flickr.photos.getRecent"
    case getInfo = "flickr.photos.getInfo"
    case getList = "flickr.photos.comments.getList"
    case addComment = "flickr.photos.comments.addComment"
    case deleteComment = "flickr.photos.comments.deleteComment"
    case addFavorites = "flickr.favorites.add"
    case removeFavorites = "flickr.favorites.remove"
    case getListFavorites = "flickr.favorites.getList"
    case getPhotos = "flickr.people.getPhotos"
    case detetePhoto = "flickr.photos.delete"
}
