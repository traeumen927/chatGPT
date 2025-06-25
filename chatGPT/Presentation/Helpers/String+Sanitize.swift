//
//  String+Sanitize.swift
//  chatGPT
//
//  Created by Codex.
//

import Foundation

extension String {
    /// Removes single and double quotes from the string
    func removingQuotes() -> String {
        self.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "'", with: "")
    }
}
