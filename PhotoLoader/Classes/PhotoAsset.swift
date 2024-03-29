//
//  PhotoAsset.swift
//  PhotoLoader
//
//  Created by Manh Luong on 02/06/2023.
//

import Foundation
import Photos
import RxSwift

public class PhotoAsset: NSObject {
    static let imageManager = PHImageManager.default()
    let asset: PHAsset
    public var id: String {
        return asset.localIdentifier
    }
    public var assetType: PhotoAssetType {
        switch asset.playbackStyle {
        case .video:
            return .video
        default:
            return .photo
        }
    }
    
    public init(asset: PHAsset) {
        self.asset = asset
        super.init()
    }
    
    public func generateVideoThumb() -> Observable<UIImage?> {
        let asset = self.asset
        
        return .create { obs in
            var requestImageID: PHImageRequestID?
            let imageManager = PHImageManager.default()
            
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            
            requestImageID = imageManager.requestAVAsset(forVideo: asset,
                                                         options: options) { avassets, avadioMix, _ in
                if let asset = avassets,
                   let image = self.generateThumnail(asset: asset, fromTime: 0.75) {
                    obs.onNext((image))
                }
            }
            
            return Disposables.create {
                if let requestID = requestImageID {
                    imageManager.cancelImageRequest(requestID)
                }
            }
        }
    }
    
    func generateThumnail(asset: AVAsset, fromTime: Float64) -> UIImage? {
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore = CMTime.zero;
        let time: CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale: 600)
        if let img = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil) {
            return UIImage(cgImage: img)
        } else {
            return nil
        }
    }
    
    public func getVideoAsset() -> Observable<AVAsset?> {
        let asset = self.asset
        
        return .create { obs in
            var requestImageID: PHImageRequestID?
            let imageManager = PHImageManager.default()
            
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            
            requestImageID = imageManager.requestAVAsset(forVideo: asset,
                                                         options: options) { avassets, avadioMix, _ in
                
                obs.onNext(avassets)
            }
            
            return Disposables.create {
                if let requestID = requestImageID {
                    imageManager.cancelImageRequest(requestID)
                }
            }
        }
    }
    
    public func thumbImage(forSize imageSize: CGSize) -> Observable<(UIImage?)> {
        guard imageSize.width > 0, imageSize.height > 0 else { return .just(nil) }
        let asset = self.asset
        let assetType = self.assetType
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.deliveryMode = .opportunistic
        return Self.imageManager.rx
            .requestImage(
                for: asset,
                targetSize: imageSize,
                contentMode: .aspectFill,
                options: requestOptions)
            .map { image, _ in image }
    }
    
    public func originalImage(
        progressHandle: @escaping ((Double) -> Void))
    -> Observable<UIImage?> {
        let asset = self.asset
        let assetSize = CGSize(
            width: asset.pixelWidth,
            height: asset.pixelHeight)
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.progressHandler = { ( progress, _, _, _) in
            progressHandle(progress)
        }
        
        return Self.imageManager.rx.requestImageData(for: asset, options: requestOptions)
            .map { $0.0 }
            .map { UIImage(data: $0) }
            .timeout(.seconds(60), scheduler: MainScheduler.instance)
    }
}
