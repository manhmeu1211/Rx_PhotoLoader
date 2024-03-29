import Photos
import RxSwift

public class PhotoLoader: NSObject {
    public override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    lazy var observableCollections: ReplaySubject<[PHFetchResult<PHAssetCollection>]> = {
        let obs = ReplaySubject<[PHFetchResult<PHAssetCollection>]>.create(bufferSize: 1)
        obs.onNext(collections)
        return obs
    }()
    
    var collections: [PHFetchResult<PHAssetCollection>] {
        var smartAlbumUserLibrary: PHFetchResult<PHAssetCollection>
        var favoriteAlbumUserLibrary: PHFetchResult<PHAssetCollection>
        let fetchOptions = PHFetchOptions()
        let sortOrder = [NSSortDescriptor(key: "endDate", ascending: false)]
        fetchOptions.sortDescriptors = sortOrder
        fetchOptions.includeAssetSourceTypes = [
            .typeCloudShared,
            .typeUserLibrary,
            .typeiTunesSynced
        ]
        smartAlbumUserLibrary = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumUserLibrary,
            options: fetchOptions)
        
        favoriteAlbumUserLibrary = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumFavorites,
            options: fetchOptions)
        
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: fetchOptions)
        
        return [smartAlbumUserLibrary, favoriteAlbumUserLibrary, userAlbums]
    }
    
    public var numberOfAlbums: Observable<Int> {
        Self.requestPermission()
            .flatMap { [weak self] in
                self?.observableCollections ?? .empty()
            }
            .map {
                $0.map { $0.count }
                    .reduce(0, { $0 + $1 })
            }
    }
    
    public func itemsForAlbum(at index: Int) -> PhotoAlbum? {
        var index = index
        for result in collections {
            guard index < result.count
            else {
                index -= result.count
                continue
            }
            return PhotoAlbum(assetCollection: result.object(at: index))
        }
        
        return nil
    }
}

extension PhotoLoader: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        observableCollections.onNext(collections)
    }
}

extension PhotoLoader {
    static func requestPermission() -> Observable<Void> {
        return .create { obs in
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    switch status {
                    case .notDetermined:
                        break
                    case .authorized:
                        obs.onNext(())
                    default:
                        obs.onError(PhotoLibraryError.notAuthorized(status: status))
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    switch status {
                    case .notDetermined:
                        break
                    case .authorized:
                        obs.onNext(())
                    default:
                        obs.onError(PhotoLibraryError.notAuthorized(status: status))
                    }
                }
            }
            return Disposables.create()
        }
    }
}

public enum PhotoLibraryError: Error {
    case notAuthorized(status: PHAuthorizationStatus)
}
