import Foundation

class Firestore {
    var documents: [String: [String: Any]] = [:]
    func document(_ path: String) -> DocumentReference { DocumentReference(store: self, path: path) }
    func collection(_ path: String) -> CollectionReference { CollectionReference(store: self, path: path) }
    static func firestore() -> Firestore { Firestore() }
}

class CollectionReference {
    let store: Firestore
    let path: String
    init(store: Firestore, path: String) { self.store = store; self.path = path }
    func document(_ id: String) -> DocumentReference { DocumentReference(store: store, path: "\(path)/\(id)") }
    func collection(_ id: String) -> CollectionReference { CollectionReference(store: store, path: "\(path)/\(id)") }
}

class DocumentReference {
    let store: Firestore
    let path: String
    init(store: Firestore, path: String) { self.store = store; self.path = path }
    func getDocument(completion: (DocumentSnapshot?, Error?) -> Void) {
        let data = store.documents[path]
        completion(DocumentSnapshot(data: data), nil)
    }
    func setData(_ data: [String: Any], completion: ((Error?) -> Void)? = nil) {
        store.documents[path] = data
        completion?(nil)
    }
    func updateData(_ data: [String: Any], completion: ((Error?) -> Void)? = nil) {
        var doc = store.documents[path] ?? [:]
        for (key, value) in data {
            if let inc = value as? Int64, key == "count" {
                let current = doc[key] as? Int ?? 0
                doc[key] = current + Int(inc)
            } else {
                doc[key] = value
            }
        }
        store.documents[path] = doc
        completion?(nil)
    }
}

class DocumentSnapshot {
    private let dataMap: [String: Any]?
    init(data: [String: Any]?) { self.dataMap = data }
    var exists: Bool { dataMap != nil }
    func data() -> [String: Any]? { dataMap }
}

class FieldValue {
    static func increment(_ value: Int64) -> Int64 { value }
}
