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
                        let deprecated = data["deprecated"] as? Bool ?? false
                        return ModelConfig(displayName: name,
                                           modelId: model,
                                           description: desc,
                                           vision: vision,
                                           enable: enable,
                                           deprecated: deprecated)
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

    func syncConfigs(with models: [OpenAIModel]) -> Single<[ModelConfig]> {
        Single.create { single in
            let collection = self.db.collection("models")
            collection.getDocuments { snapshot, error in
                if let error = error { single(.failure(error)); return }

                let docs = snapshot?.documents ?? []
                var configs: [String: ModelConfig] = [:]
                var references: [String: DocumentReference] = [:]

                docs.forEach { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let model = data["model"] as? String,
                          let desc = data["description"] as? String,
                          let vision = data["vision"] as? Bool else { return }
                    let enable = data["enable"] as? Bool ?? false
                    let deprecated = data["deprecated"] as? Bool ?? false
                    let config = ModelConfig(displayName: name,
                                             modelId: model,
                                             description: desc,
                                             vision: vision,
                                             enable: enable,
                                             deprecated: deprecated)
                    configs[model] = config
                    references[model] = doc.reference
                }

                let availableSet = Set(models.map { $0.id })
                var operations: [(DocumentReference, [String: Any], Bool)] = [] // bool indicates new doc

                models.forEach { model in
                    if let existing = configs[model.id] {
                        if existing.deprecated {
                            operations.append((references[model.id]!, ["deprecated": false], false))
                            configs[model.id] = ModelConfig(displayName: existing.displayName,
                                                           modelId: existing.modelId,
                                                           description: existing.description,
                                                           vision: existing.vision,
                                                           enable: existing.enable,
                                                           deprecated: false)
                        }
                    } else {
                        let data: [String: Any] = [
                            "name": model.id,
                            "model": model.id,
                            "description": "",
                            "vision": false,
                            "enable": false,
                            "deprecated": false
                        ]
                        let ref = collection.document(model.id)
                        operations.append((ref, data, true))
                        configs[model.id] = ModelConfig(displayName: model.id,
                                                        modelId: model.id,
                                                        description: "",
                                                        vision: false,
                                                        enable: false,
                                                        deprecated: false)
                    }
                }

                configs.keys.forEach { key in
                    if !availableSet.contains(key) {
                        if let existing = configs[key], !existing.deprecated {
                            if let ref = references[key] {
                                operations.append((ref, ["deprecated": true], false))
                                configs[key] = ModelConfig(displayName: existing.displayName,
                                                            modelId: existing.modelId,
                                                            description: existing.description,
                                                            vision: existing.vision,
                                                            enable: existing.enable,
                                                            deprecated: true)
                            }
                        }
                    }
                }

                let group = DispatchGroup()
                var firstError: Error?
                operations.forEach { ref, data, isNew in
                    group.enter()
                    if isNew {
                        ref.setData(data) { err in
                            if let err = err { firstError = err }
                            group.leave()
                        }
                    } else {
                        ref.setData(data, merge: true) { err in
                            if let err = err { firstError = err }
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .main) {
                    if let error = firstError {
                        single(.failure(error))
                    } else {
                        let result = configs.values.filter { $0.enable && !$0.deprecated }
                        single(.success(Array(result)))
                    }
                }
            }
            return Disposables.create()
        }
    }
}
