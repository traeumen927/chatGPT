import UIKit
import Down

final class DownMarkdownRepository: MarkdownRepository {
    private let codeRegex = try! NSRegularExpression(pattern: "```(.*?)\\n([\\s\\S]*?)```", options: [])

    func parse(_ markdown: String) -> NSAttributedString {
        let matches = codeRegex.matches(in: markdown, options: [], range: NSRange(location: 0, length: markdown.utf16.count))

        var parts: [NSAttributedString] = []
        var currentLocation = markdown.startIndex

        for match in matches {
            guard let range = Range(match.range, in: markdown) else { continue }
            let beforeText = String(markdown[currentLocation..<range.lowerBound])
            if !beforeText.isEmpty {
                parts.append(htmlToAttributed(beforeText))
            }

            let codeRange = Range(match.range(at: 2), in: markdown)!
            let code = String(markdown[codeRange])
            let attachment = CodeBlockAttachment(code: code)
            parts.append(NSAttributedString(attachment: attachment))

            currentLocation = range.upperBound
        }

        let remaining = String(markdown[currentLocation...])
        if !remaining.isEmpty {
            parts.append(htmlToAttributed(remaining))
        }

        let result = NSMutableAttributedString()
        parts.forEach { result.append($0) }
        let range = NSRange(location: 0, length: result.length)
        result.removeAttribute(.foregroundColor, range: range)
        result.addAttribute(.foregroundColor, value: UIColor.label, range: range)
        while result.string.hasSuffix("\n") {
            result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
        }
        return result
    }

    private func htmlToAttributed(_ markdown: String) -> NSAttributedString {
        guard let html = try? Down(markdownString: markdown).toHTML() else {
            return NSAttributedString(string: markdown)
        }

        let styledHTML = """
        <html>
        <head>
        <meta name=\"color-scheme\" content=\"light dark\">
        <style>
        body { font-family: -apple-system; font-size: 16px; }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """

        guard let data = styledHTML.data(using: .utf8) else {
            return NSAttributedString(string: markdown)
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributed = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) {
            while attributed.string.hasSuffix("\n") {
                attributed.deleteCharacters(in: NSRange(location: attributed.length - 1, length: 1))
            }
            return attributed
        }
        return NSAttributedString(string: markdown)
    }
}
