import Foundation

class Firestore {
    var documents: [String: [String: Any]] = [:]
    func document(_ path: String) -> DocumentReference { DocumentReference(store: self, path: path) }
    func collection(_ path: String) -> CollectionReference { CollectionReference(store: self, path: path) }
    static func firestore() -> Firestore { Firestore() }
}

typealias Query = CollectionReference

class CollectionReference {
    let store: Firestore
    let path: String
    init(store: Firestore, path: String) { self.store = store; self.path = path }
    func document(_ id: String) -> DocumentReference { DocumentReference(store: store, path: "\(path)/\(id)") }
    func collection(_ id: String) -> CollectionReference { CollectionReference(store: store, path: "\(path)/\(id)") }
    func whereField(_ field: String, isGreaterThan value: TimeInterval) -> CollectionReference { self }
    func getDocuments(completion: (QuerySnapshot?, Error?) -> Void) {
        let prefix = path + "/"
        var docs: [QueryDocumentSnapshot] = []
        for (key, value) in store.documents where key.hasPrefix(prefix) {
            let id = String(key.dropFirst(prefix.count))
            docs.append(QueryDocumentSnapshot(documentID: id, data: value))
        }
        completion(QuerySnapshot(documents: docs), nil)
    }

    func addSnapshotListener(_ listener: @escaping (QuerySnapshot?, Error?) -> Void) -> ListenerRegistration {
        let prefix = path + "/"
        var docs: [QueryDocumentSnapshot] = []
        for (key, value) in store.documents where key.hasPrefix(prefix) {
            let id = String(key.dropFirst(prefix.count))
            docs.append(QueryDocumentSnapshot(documentID: id, data: value))
        }
        listener(QuerySnapshot(documents: docs), nil)
        return ListenerRegistration {}
    }
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

class QueryDocumentSnapshot {
    let documentID: String
    private let dataMap: [String: Any]
    init(documentID: String, data: [String: Any]) {
        self.documentID = documentID
        self.dataMap = data
    }
    func data() -> [String: Any] { dataMap }
}

class QuerySnapshot {
    let documents: [QueryDocumentSnapshot]
    init(documents: [QueryDocumentSnapshot]) { self.documents = documents }
}

class FieldValue {
    static func increment(_ value: Int64) -> Int64 { value }
}

class ListenerRegistration {
    private let onRemove: () -> Void
    init(_ onRemove: @escaping () -> Void) { self.onRemove = onRemove }
    func remove() { onRemove() }
}
