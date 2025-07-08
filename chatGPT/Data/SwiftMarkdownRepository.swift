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
                } else if case .heading(let level) = run.presentationIntent {
                    let size: CGFloat
                    switch level {
                    case 1: size = 24
                    case 2: size = 22
                    case 3: size = 20
                    default: size = 18
                    }
                    attr[range].font = UIFont.boldSystemFont(ofSize: size)
                    attr[range].foregroundColor = UIColor.label
                } else {
                    attr[range].font = UIFont.systemFont(ofSize: 16)
                    attr[range].foregroundColor = UIColor.label
                }
            }

            var ns = NSMutableAttributedString(attr)
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
            return ns
        } else {
            return NSAttributedString(string: markdown, attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ])
        }
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
