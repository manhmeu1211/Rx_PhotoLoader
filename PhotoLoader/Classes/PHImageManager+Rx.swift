//
//  PHImageManager+Rx.swift
//  PhotoLoader
//
//  Created by Manh Luong on 05/06/2023.
//

import UIKit
import Photos
import RxSwift

extension Reactive where Base: PHImageManager {
    
    public func requestImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?) -> Observable<(UIImage, [AnyHashable: Any]?)> {
        
        return Observable.create({ [weak manager = self.base] (observer) -> Disposable in
            guard let manager = manager else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            let requestID = manager
                .requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options, resultHandler: { (image, info) in
                    if let image = image {
                        observer.onNext((image, info))
                    }
                    
                    if let error = info?[PHImageErrorKey] as? NSError {
                        observer.onError(error)
                    }
                    
                    if let isTemporaryImage = info?[PHImageResultIsDegradedKey] as? Bool,
                       isTemporaryImage == false {
                        observer.onCompleted()
                    }
                })
            
            return Disposables.create {
                manager.cancelImageRequest(requestID)
            }
            
        })
        
    }
    
    public func requestImageData(for asset: PHAsset, options: PHImageRequestOptions?) -> Observable<(Data, String?, UIImage.Orientation, [AnyHashable : Any]?)> {
        
        return Observable.create({ [weak manager = self.base] (observer) -> Disposable in
            guard let manager = manager else {
                observer.onCompleted()
                return Disposables.create()
            }
            var requestID: PHImageRequestID?
            
            if #available(iOS 13, *) {
                manager
                    .requestImageDataAndOrientation(for: asset, options: options, resultHandler: { (data, string, imageOrientation, info) in
                        if let error = info?[PHImageErrorKey] as? NSError {
                            observer.onError(error)
                        } else if let data = data {
                            let orientation = UIImage.Orientation(rawValue: Int(imageOrientation.rawValue)) ?? .up
                            observer.onNext((data, string, orientation, info))
                            observer.onCompleted()
                        }
                    })
            } else {
                manager
                    .requestImageData(for: asset, options: options, resultHandler: { (data, string, imageOrientation, info) in
                        if let error = info?[PHImageErrorKey] as? NSError {
                            observer.onError(error)
                        } else if let data = data {
                            observer.onNext((data, string, imageOrientation, info))
                            observer.onCompleted()
                        }
                    })
            }
            return Disposables.create {
                
                requestID.map { manager.cancelImageRequest($0) }
            }
            
        })
        
    }
    
}
