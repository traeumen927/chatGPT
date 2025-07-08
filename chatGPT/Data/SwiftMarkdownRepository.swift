import UIKit
import Markdown

final class SwiftMarkdownRepository: MarkdownRepository {
    private let codeRegex = try! NSRegularExpression(pattern: "```(.*?)\\n([\\s\\S]*?)```", options: [])

    func parse(_ markdown: String) -> NSAttributedString {
        let matches = codeRegex.matches(in: markdown, options: [], range: NSRange(location: 0, length: markdown.utf16.count))
        var parts: [NSAttributedString] = []
        var currentLocation = markdown.startIndex

        for match in matches {
            guard let range = Range(match.range, in: markdown) else { continue }
            let beforeText = String(markdown[currentLocation..<range.lowerBound])
            if !beforeText.isEmpty {
                parts.append(attributed(from: beforeText))
            }

            let codeRange = Range(match.range(at: 2), in: markdown)!
            let code = String(markdown[codeRange])
            let attachment = CodeBlockAttachment(code: code)
            parts.append(NSAttributedString(attachment: attachment))

            currentLocation = range.upperBound
        }

        let remaining = String(markdown[currentLocation...])
        if !remaining.isEmpty {
            parts.append(attributed(from: remaining))
        }

        let result = NSMutableAttributedString()
        parts.forEach { result.append($0) }
        while result.string.hasSuffix("\n") {
            result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
        }
        return result
    }

    private func attributed(from markdown: String) -> NSAttributedString {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
        let result = NSMutableAttributedString()

        var buffer = ""
        var index = 0
        while index < lines.count {
            let line = String(lines[index])

            if line.trimmingCharacters(in: .whitespaces) == "---" {
                if !buffer.isEmpty {
                    result.append(parseSegment(buffer))
                    buffer.removeAll()
                }
                result.append(NSAttributedString(attachment: HorizontalRuleAttachment()))
                index += 1
            } else if line.starts(with: "|") {
                if !buffer.isEmpty {
                    result.append(parseSegment(buffer))
                    buffer.removeAll()
                }
                var tableLines: [String] = []
                while index < lines.count && lines[index].starts(with: "|") {
                    tableLines.append(String(lines[index]))
                    index += 1
                }
                if let attachment = makeTableAttachment(from: tableLines) {
                    result.append(NSAttributedString(attachment: attachment))
                }
            } else {
                buffer += line
                if index < lines.count - 1 { buffer += "\n" }
                index += 1
            }

            if index == lines.count && !buffer.isEmpty {
                result.append(parseSegment(buffer))
                buffer.removeAll()
            }
        }

        return result
    }

    private func parseSegment(_ markdown: String) -> NSAttributedString {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
        let result = NSMutableAttributedString()
        var buffer = ""

        func flushBuffer() {
            guard !buffer.isEmpty else { return }
            result.append(parseBody(buffer))
            buffer.removeAll()
        }

        for (index, lineSub) in lines.enumerated() {
            let line = String(lineSub)
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                flushBuffer()
                result.append(parseHeading(from: line))
                if index < lines.count - 1 { result.append(NSAttributedString(string: "\n")) }
            } else {
                buffer += line
                if index < lines.count - 1 { buffer += "\n" }
            }
        }

        flushBuffer()
        return result
    }

    private func parseBody(_ markdown: String) -> NSAttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .full
        options.allowsExtendedAttributes = true

        if var attr = try? AttributedString(markdown: markdown, options: options) {
            for run in attr.runs {
                let range = run.range
                if run.inlinePresentationIntent == .code {
                    attr[range].font = UIFont(name: "Menlo", size: 16) ?? UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
                    attr[range].foregroundColor = ThemeColor.negative
                    attr[range].backgroundColor = ThemeColor.inlineCodeBackground
                } else {
                    attr[range].font = UIFont.systemFont(ofSize: 16)
                    attr[range].foregroundColor = UIColor.label
                }
            }

            let ns = NSMutableAttributedString(attr)
            applyBulletStyle(to: ns)
            return ns
        } else {
            let ns = NSMutableAttributedString(string: markdown, attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ])
            applyFallbackListStyle(to: ns)
            return ns
        }
    }

    private func parseHeading(from line: String) -> NSAttributedString {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let level = min(trimmed.prefix { $0 == "#" }.count, 6)
        var content = String(trimmed.drop(while: { $0 == "#" }))
        if content.hasPrefix(" ") { content.removeFirst() }

        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .full
        options.allowsExtendedAttributes = true

        func fontSize() -> CGFloat {
            switch level {
            case 1: return 24
            case 2: return 22
            case 3: return 20
            default: return 18
            }
        }

        if var attr = try? AttributedString(markdown: content, options: options) {
            for run in attr.runs {
                let range = run.range
                if run.inlinePresentationIntent == .code {
                    attr[range].font = UIFont(name: "Menlo", size: 16) ?? UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
                    attr[range].foregroundColor = ThemeColor.negative
                    attr[range].backgroundColor = ThemeColor.inlineCodeBackground
                } else {
                    attr[range].font = UIFont.boldSystemFont(ofSize: fontSize())
                    attr[range].foregroundColor = UIColor.label
                }
            }
            return NSAttributedString(attr)
        } else {
            return NSAttributedString(string: content, attributes: [
                .font: UIFont.boldSystemFont(ofSize: fontSize()),
                .foregroundColor: UIColor.label
            ])
        }
    }

    private func applyBulletStyle(to ns: NSMutableAttributedString) {
        let pattern = "^(?:\\u{2022}|\\d+\\.)\\s"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
            let entire = NSRange(location: 0, length: ns.length)
            regex.enumerateMatches(in: ns.string, options: [], range: entire) { match, _, _ in
                guard let m = match else { return }
                let paragraphRange = (ns.string as NSString).paragraphRange(for: m.range)
                let style = NSMutableParagraphStyle()
                style.headIndent = 16
                ns.addAttribute(.paragraphStyle, value: style, range: paragraphRange)
            }
        }
    }

    private func applyFallbackListStyle(to ns: NSMutableAttributedString) {
        let lines = ns.string.split(separator: "\n", omittingEmptySubsequences: false)
        let result = NSMutableAttributedString()
        for (index, line) in lines.enumerated() {
            var text = String(line)
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            var bullet: String?

            if trimmed.hasPrefix("- ") {
                bullet = "\u{2022} "
                text = String(trimmed.dropFirst(2))
            } else if let range = trimmed.range(of: "^\\d+\\. ", options: .regularExpression) {
                bullet = String(trimmed[range])
                text = String(trimmed[range.upperBound...])
            } else {
                text = trimmed
            }

            var attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]

            if let bullet = bullet {
                let style = NSMutableParagraphStyle()
                style.headIndent = 16
                attributes[.paragraphStyle] = style
                result.append(NSAttributedString(string: bullet + text, attributes: attributes))
            } else {
                result.append(NSAttributedString(string: text, attributes: attributes))
            }

            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        ns.setAttributedString(result)
    }

    private func makeTableAttachment(from lines: [String]) -> TableBlockAttachment? {
        guard lines.count >= 2 else { return nil }
        let header = parseCells(from: lines[0])
        var rows: [[String]] = [header]
        for line in lines.dropFirst(2) {
            rows.append(parseCells(from: line))
        }
        return TableBlockAttachment(rows: rows)
    }

    private func parseCells(from line: String) -> [String] {
        var temp = line
        temp = temp.trimmingCharacters(in: .whitespaces)
        if temp.hasPrefix("|") { temp.removeFirst() }
        if temp.hasSuffix("|") { temp.removeLast() }
        return temp.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
