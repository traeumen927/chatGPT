import Foundation

class Firestore {
    var lastBatch: WriteBatch?
    func batch() -> WriteBatch { let b = WriteBatch(); lastBatch = b; return b }
    func collection(_ path: String) -> CollectionReference { CollectionReference(path: path) }
    static func firestore() -> Firestore { Firestore() }
}

class CollectionReference {
    let path: String
    init(path: String) { self.path = path }
    func document(_ id: String) -> DocumentReference { DocumentReference(path: "\(path)/\(id)") }
    func collection(_ id: String) -> CollectionReference { CollectionReference(path: "\(path)/\(id)") }
}

class DocumentReference {
    let path: String
    init(path: String) { self.path = path }
}

class WriteBatch {
    struct SetCall { let data: [String: Any]; let document: DocumentReference; let merge: Bool }
    var setCalls: [SetCall] = []
    func setData(_ data: [String: Any], forDocument document: DocumentReference, merge: Bool) {
        setCalls.append(SetCall(data: data, document: document, merge: merge))
    }
    func commit(completion: ((Error?) -> Void)? = nil) { completion?(nil) }
}

class FieldValue {
    static func increment(_ value: Int64) -> Int64 { value }
}
