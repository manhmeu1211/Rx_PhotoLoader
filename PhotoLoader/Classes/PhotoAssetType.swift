//
//  PhotoAssetType.swift
//  PhotoLoader
//
//  Created by Manh Luong on 02/06/2023.
//

import Foundation

public enum PhotoAssetType {
    case photo
    case video
}

extension PhotoAssetType {
    var typeName: String {
        switch self {
        case .photo:
            return "public.image"
        case .video:
            return "public.movie"
        }
    }
}
