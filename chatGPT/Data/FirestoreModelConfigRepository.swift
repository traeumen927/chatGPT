import Foundation
import FirebaseFirestore
import RxSwift

final class FirestoreModelConfigRepository: ModelConfigRepository {
    private let db = Firestore.firestore()

    func fetchConfigs() -> Single<[ModelConfig]> {
        Single.create { single in
            self.db.collection("models").getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    let configs: [ModelConfig] = docs.compactMap { doc in
                        let data = doc.data()
                        guard let name = data["name"] as? String,
                              let model = data["model"] as? String,
                              let desc = data["description"] as? String,
                              let vision = data["vision"] as? Bool else { return nil }
                        return ModelConfig(displayName: name,
                                           modelId: model,
                                           description: desc,
                                           vision: vision)
                    }
                    single(.success(configs))
                } else if let error = error {
                    single(.failure(error))
                } else {
                    single(.success([]))
                }
            }
            return Disposables.create()
        }
    }
}
