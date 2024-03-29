//
//  PhotoAlbum.swift
//  PhotoLoader
//
//  Created by Manh Luong on 02/06/2023.
//

import Foundation
import Photos
import RxSwift

public class PhotoAlbum: NSObject {
    static let imageManager = PHImageManager.default()
    
    let assetCollection: PHAssetCollection
    
    init(assetCollection: PHAssetCollection) {
        self.assetCollection = assetCollection
        super.init()
    }
    
    lazy var allAssets: PHFetchResult<PHAsset> = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAssetSourceTypes = [.typeCloudShared, .typeUserLibrary, .typeCloudShared]
        let sortOrder = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.sortDescriptors = sortOrder
        return PHAsset.fetchAssets(
            in: assetCollection,
            options: fetchOptions)
    }()
    
    public func asset(at index: Int) -> Observable<PhotoAsset?> {
        return Observable.just(())
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .compactMap { [weak self] in self?.allAssets }
            .map { $0.object(at: index) }
            .map { PhotoAsset(asset: $0) }
    }
    
    public var albumTitle: String {
        return assetCollection.localizedTitle ?? ""
    }
    
    public var imagesCount: Int {
        return allAssets.count
    }
    
    public func thumImage(forSize imageSize: CGSize) -> Observable<UIImage?> {
        guard let firstObject = allAssets.firstObject else { return .just(nil) }
        return PhotoAsset(asset: firstObject).thumbImage(forSize: imageSize)
    }
}
