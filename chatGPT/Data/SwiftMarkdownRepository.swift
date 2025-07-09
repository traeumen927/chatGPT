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

        var index = 0
        while index < lines.count {
            let line = String(lines[index])

            if line.trimmingCharacters(in: .whitespaces) == "---" {
                let attachment = HorizontalRuleAttachment()
                result.append(NSAttributedString(attachment: attachment))
                index += 1
            } else if line.starts(with: "|") {
                var tableLines: [String] = []
                while index < lines.count && lines[index].starts(with: "|") {
                    tableLines.append(String(lines[index]))
                    index += 1
                }
                if let attachment = makeTableAttachment(from: tableLines) {
                    result.append(NSAttributedString(attachment: attachment))
                }
            } else if line.trimmingCharacters(in: .whitespaces).hasPrefix("- ") {
                var listLines: [String] = []
                while index < lines.count && lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("- ") {
                    listLines.append(String(lines[index]))
                    index += 1
                }
                result.append(makeBulletList(from: listLines))
            } else {
                var options = AttributedString.MarkdownParsingOptions()
                options.interpretedSyntax = .inlineOnlyPreservingWhitespace
                options.allowsExtendedAttributes = true

                if var attr = try? AttributedString(markdown: line, options: options) {

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

                    result.append(NSAttributedString(attr))
                } else {
                    result.append(NSAttributedString(string: line, attributes: [
                        .font: UIFont.systemFont(ofSize: 16),
                        .foregroundColor: UIColor.label
                    ]))
                }
                index += 1
            }

            if index < lines.count {
                result.append(NSAttributedString(string: "\n"))
            }
        }

        return result
    }

    private func makeBulletList(from lines: [String]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for (idx, line) in lines.enumerated() {
            var item = line
            if let range = item.range(of: "- ") {
                item = String(item[range.upperBound...])
            }

            var options = AttributedString.MarkdownParsingOptions()
            options.interpretedSyntax = .inlineOnlyPreservingWhitespace
            options.allowsExtendedAttributes = true

            if var attr = try? AttributedString(markdown: item, options: options) {
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
                result.append(NSAttributedString(string: "\u{2022} "))
                result.append(NSAttributedString(attr))
            } else {
                result.append(NSAttributedString(string: "\u{2022} " + item, attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.label
                ]))
            }
            if idx != lines.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        return result
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
