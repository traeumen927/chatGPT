import Foundation
import FirebaseStorage
import RxSwift

final class FirebaseStorageRepository: FileStorageRepository {
    private let storage = Storage.storage()

    func upload(data: Data, path: String) -> Single<URL> {
        Single.create { single in
            let ref = self.storage.reference(withPath: path)
            ref.putData(data) { _, error in
                if let error = error {
                    single(.failure(error))
                } else {
                    ref.downloadURL { url, error in
                        if let error = error {
                            single(.failure(error))
                        } else if let url = url {
                            single(.success(url))
                        } else {
                            single(.failure(NSError(domain: "upload", code: -1)))
                        }
                    }
                }
            }
            return Disposables.create()
        }
    }
}
