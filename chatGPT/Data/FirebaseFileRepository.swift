import Foundation
import FirebaseStorage
import RxSwift

final class FirebaseFileRepository: FileRepository {
    private let storage = Storage.storage()

    private func fileInfo(for data: Data) -> (ext: String, mime: String) {
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return ("jpg", "image/jpeg") }
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return ("png", "image/png") }
        return ("dat", "application/octet-stream")
    }

    func uploadFiles(uid: String, datas: [Data]) -> Single<[URL]> {
        Single.create { single in
            var urls: [URL] = []
            let group = DispatchGroup()

            for data in datas {
                group.enter()
                let id = UUID().uuidString
                let info = self.fileInfo(for: data)
                let ref = self.storage.reference().child("attachments/\(uid)/\(id).\(info.ext)")
                let metadata = StorageMetadata()
                metadata.contentType = info.mime
                ref.putData(data, metadata: metadata) { _, error in
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
