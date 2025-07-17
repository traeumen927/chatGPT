import UIKit

enum Attachment: Hashable {
    case image(UIImage)
    case file(URL)
    case remoteImage(URL)
    case remoteFile(URL)

    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        switch (lhs, rhs) {
        case (.image(let l), .image(let r)): return l == r
        case (.file(let l), .file(let r)): return l == r
        case (.remoteImage(let l), .remoteImage(let r)): return l == r
        case (.remoteFile(let l), .remoteFile(let r)): return l == r
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .image(let img): hasher.combine(img.hash)
        case .file(let url): hasher.combine(url)
        case .remoteImage(let url): hasher.combine(url)
        case .remoteFile(let url): hasher.combine(url)
        }
    }
}
