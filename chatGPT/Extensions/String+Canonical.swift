import Foundation

extension String {
    /// Returns a canonical identifier by lowercasing and removing non-alphanumeric characters.
    func factIdentifier() -> String {
        lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}
