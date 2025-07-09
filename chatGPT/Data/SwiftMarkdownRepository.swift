import UIKit
import Markdown

final class SwiftMarkdownRepository: MarkdownRepository {
    // ``` 코드 블럭을 추출하기 위한 정규식
    private let codeRegex = try! NSRegularExpression(pattern: "```(.*?)\\n([\\s\\S]*?)```", options: [])
    
    /// 전체 마크다운 문자열을 코드 블럭 기준으로 분리하여 파싱한다
    func parse(_ markdown: String) -> NSAttributedString {
        // 코드 블럭 찾기
        let matches = codeRegex.matches(in: markdown, options: [], range: NSRange(location: 0, length: markdown.utf16.count))
        var parts: [NSAttributedString] = []
        var currentLocation = markdown.startIndex

        for match in matches {
            guard let range = Range(match.range, in: markdown) else { continue }
            // 코드 블럭 앞의 일반 마크다운 처리
            let beforeText = String(markdown[currentLocation..<range.lowerBound])
            if !beforeText.isEmpty {
                parts.append(attributed(from: beforeText))
            }

            let codeRange = Range(match.range(at: 2), in: markdown)!
            let code = String(markdown[codeRange])
            // 코드 블럭에 대한 Attachment 생성
            let attachment = CodeBlockAttachment(code: code)
            parts.append(NSAttributedString(attachment: attachment))
            
            currentLocation = range.upperBound
        }
        
        // 남은 마크다운 처리
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
    
    /// 코드 블럭 외의 일반 마크다운을 라인 단위로 처리
    private func attributed(from markdown: String) -> NSAttributedString {
        // 줄 단위로 분리
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
        let result = NSMutableAttributedString()

        var index = 0
        while index < lines.count {
            let line = String(lines[index])

            // 수평선(`---`)
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                let attachment = HorizontalRuleAttachment()
                result.append(NSAttributedString(attachment: attachment))
                index += 1
            // 테이블(`|`로 시작하는 라인들)
            } else if line.starts(with: "|") {
                var tableLines: [String] = []
                while index < lines.count && lines[index].starts(with: "|") {
                    tableLines.append(String(lines[index]))
                    index += 1
                }
                if let attachment = makeTableAttachment(from: tableLines) {
                    result.append(NSAttributedString(attachment: attachment))
                }
            // 헤딩(`#`, `##`, `###`)
            } else if let headingLevel = headingLevel(in: line) {
                let content = headingContent(from: line, level: headingLevel)

                var options = AttributedString.MarkdownParsingOptions()
                options.interpretedSyntax = .inlineOnlyPreservingWhitespace
                options.allowsExtendedAttributes = true

                let fontSize: CGFloat
                switch headingLevel {
                case 1: fontSize = 28
                case 2: fontSize = 24
                default: fontSize = 20
                }

                if var attr = try? AttributedString(markdown: content, options: options) {
                    for run in attr.runs {
                        let range = run.range
                        if run.inlinePresentationIntent == .code {
                            attr[range].font = UIFont(name: "Menlo", size: 16) ?? UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
                            attr[range].foregroundColor = ThemeColor.negative
                            attr[range].backgroundColor = ThemeColor.inlineCodeBackground
                        } else {
                            attr[range].font = UIFont.boldSystemFont(ofSize: fontSize)
                            attr[range].foregroundColor = UIColor.label
                        }
                    }
                    result.append(NSAttributedString(attr))
                } else {
                    result.append(NSAttributedString(string: content, attributes: [
                        .font: UIFont.boldSystemFont(ofSize: fontSize),
                        .foregroundColor: UIColor.label
                    ]))
                }
                index += 1
            // 순번(`1. `) 목록
            } else if orderedListNumber(in: line) != nil {
                var listLines: [String] = []
                while index < lines.count && orderedListNumber(in: String(lines[index])) != nil {
                    listLines.append(String(lines[index]))
                    index += 1
                }
                result.append(makeOrderedList(from: listLines))
            // 글머리표(`- `) 목록
            } else if line.trimmingCharacters(in: .whitespaces).hasPrefix("- ") {
                var listLines: [String] = []
                while index < lines.count && lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("- ") {
                    listLines.append(String(lines[index]))
                    index += 1
                }
                result.append(makeBulletList(from: listLines))
            // 그 외 일반 텍스트 라인
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

    /// `-` 로 시작하는 목록을 NSAttributedString으로 변환
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
                let bullet = NSAttributedString(
                    string: "\u{2022} ",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 16),
                        .foregroundColor: UIColor.label
                    ]
                )
                result.append(bullet)
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

    /// `1. ` 형태의 순번 목록을 NSAttributedString으로 변환
    private func makeOrderedList(from lines: [String]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for (idx, line) in lines.enumerated() {
            var item = line
            if let range = item.range(of: "^\\d+\\. ", options: .regularExpression) {
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
                let bullet = NSAttributedString(
                    string: "\(idx + 1). ",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 16),
                        .foregroundColor: UIColor.label
                    ]
                )
                result.append(bullet)
                result.append(NSAttributedString(attr))
            } else {
                result.append(NSAttributedString(string: "\(idx + 1). " + item, attributes: [
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

    /// 순번 목록 여부를 판별
    private func orderedListNumber(in line: String) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        var digits = ""
        var idx = trimmed.startIndex
        while idx < trimmed.endIndex, trimmed[idx].isNumber {
            digits.append(trimmed[idx])
            idx = trimmed.index(after: idx)
        }
        guard !digits.isEmpty, idx < trimmed.endIndex, trimmed[idx] == "." else {
            return nil
        }
        idx = trimmed.index(after: idx)
        guard idx < trimmed.endIndex, trimmed[idx] == " " else { return nil }
        return Int(digits)
    }

    /// `|` 로 이루어진 마크다운 테이블을 Attachment로 변환
    private func makeTableAttachment(from lines: [String]) -> TableBlockAttachment? {
        guard lines.count >= 2 else { return nil }
        let header = parseCells(from: lines[0])
        var rows: [[String]] = [header]
        for line in lines.dropFirst(2) {
            rows.append(parseCells(from: line))
        }
        return TableBlockAttachment(rows: rows)
    }

    /// 테이블 한 줄을 셀 배열로 변환
    private func parseCells(from line: String) -> [String] {
        var temp = line
        temp = temp.trimmingCharacters(in: .whitespaces)
        if temp.hasPrefix("|") { temp.removeFirst() }
        if temp.hasSuffix("|") { temp.removeLast() }
        return temp.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// 헤딩 레벨(`###`, `##`, `#`)을 판별
    private func headingLevel(in line: String) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("### ") { return 3 }
        if trimmed.hasPrefix("## ") { return 2 }
        if trimmed.hasPrefix("# ") { return 1 }
        return nil
    }

    /// 헤딩에서 `#` 표시를 제외한 본문 추출
    private func headingContent(from line: String, level: Int) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let start = trimmed.index(trimmed.startIndex, offsetBy: level + 1)
        return String(trimmed[start...])
    }
}
