import UIKit
import Down

final class DownMarkdownRepository: MarkdownRepository {
    func parse(_ markdown: String) -> NSAttributedString {
        // 마크다운을 HTML로 변환 후 스타일을 입혀 NSAttributedString으로 반환
        guard let html = try? Down(markdownString: markdown).toHTML() else {
            return NSAttributedString(string: markdown)
        }

        let styledHTML = """
        <html>
        <head>
        <style>
        body { font-family: -apple-system; font-size: 16px; }
        pre { background-color: #F5F5F5; padding: 8px; border-radius: 4px; }
        code { font-family: Menlo; }
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

        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed
        }

        return NSAttributedString(string: markdown)
    }
}
