import Foundation
import FirebaseStorage
import RxSwift

final class FirebaseFileRepository: FileRepository {
    private let storage = Storage.storage()

    func uploadFiles(uid: String, datas: [Data]) -> Single<[URL]> {
        Single.create { single in
            var urls: [URL] = []
            let group = DispatchGroup()

            for data in datas {
                group.enter()
                let id = UUID().uuidString
                let ref = self.storage.reference().child("attachments/\(uid)/\(id)")
                ref.putData(data, metadata: nil) { _, error in
                    if let error = error {
                        group.leave()
                        single(.failure(error))
                        return
                    }
                    ref.downloadURL { url, error in
                        if let url = url {
                            urls.append(url)
                        }
                        group.leave()
                        if let error = error {
                            single(.failure(error))
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                single(.success(urls))
            }

            return Disposables.create()
        }
    }
}
