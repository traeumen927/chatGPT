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
                        let enable = data["enable"] as? Bool ?? false
                        return ModelConfig(displayName: name,
                                           modelId: model,
                                           description: desc,
                                           vision: vision,
                                           enabled: enable)
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

    func syncModels(with available: [OpenAIModel]) -> Single<[ModelConfig]> {
        Single.create { single in
            let collection = self.db.collection("models")
            collection.getDocuments { snapshot, error in
                guard let docs = snapshot?.documents, error == nil else {
                    if let error = error {
                        single(.failure(error))
                    } else {
                        single(.success([]))
                    }
                    return
                }

                let availableSet = Set(available.map { $0.id })
                var existing: [String: QueryDocumentSnapshot] = [:]
                docs.forEach { doc in
                    if let id = doc.data()["model"] as? String {
                        existing[id] = doc
                    }
                }

                let group = DispatchGroup()
                var firstError: Error?

                available.forEach { model in
                    if existing[model.id] == nil {
                        group.enter()
                        let data: [String: Any] = [
                            "name": model.id,
                            "model": model.id,
                            "description": "",
                            "vision": false,
                            "enable": false
                        ]
                        collection.document(model.id).setData(data) { err in
                            if let err = err { firstError = err }
                            group.leave()
                        }
                    }
                }

                for doc in docs {
                    guard let id = doc.data()["model"] as? String else { continue }
                    let enabled = doc.data()["enable"] as? Bool ?? false
                    if enabled && !availableSet.contains(id) {
                        group.enter()
                        collection.document(doc.documentID).updateData(["enable": false]) { err in
                            if let err = err { firstError = err }
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main) {
                    if let err = firstError {
                        single(.failure(err))
                        return
                    }
                    collection.whereField("enable", isEqualTo: true).getDocuments { snap, err in
                        if let err = err {
                            single(.failure(err))
                        } else if let docs = snap?.documents {
                            let configs: [ModelConfig] = docs.compactMap { doc in
                                let data = doc.data()
                                guard let name = data["name"] as? String,
                                      let model = data["model"] as? String,
                                      let desc = data["description"] as? String,
                                      let vision = data["vision"] as? Bool else { return nil }
                                return ModelConfig(displayName: name,
                                                   modelId: model,
                                                   description: desc,
                                                   vision: vision,
                                                   enabled: true)
                            }
                            single(.success(configs))
                        } else {
                            single(.success([]))
                        }
                    }
                }
            }
            return Disposables.create()
        }
    }
}
