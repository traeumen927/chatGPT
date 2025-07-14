import UIKit
import Markdown

final class SwiftMarkdownRepository: MarkdownRepository {
    // ``` 코드 블럭을 추출하기 위한 정규식
    // 3개 이상의 백틱을 동일한 길이의 백틱으로 닫는 패턴으로 수정하여
    // 코드 블럭 내부에 ``` 문자열이 포함되어도 올바르게 파싱되도록 개선합니다.
    // 닫는 백틱 뒤에 공백이 올 수 있도록 패턴을 보강합니다.

    private let openRegex = try! NSRegularExpression(
        pattern: "^([ \\t]*)(`{3,})([^\\n]*)$",
        options: []
    )
    
    private let imageRegex = try! NSRegularExpression(
        pattern: "!\[([^\]]*)\]\(([^\)]+)\)",
        options: []
    )

    /// 전체 마크다운 문자열을 코드 블럭 기준으로 분리하여 파싱한다
    func parse(_ markdown: String) -> NSAttributedString {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var parts: [NSAttributedString] = []
        var buffer: [String] = []

        func flush() {
            guard !buffer.isEmpty else { return }
            parts.append(attributed(from: buffer.joined(separator: "\n")))
            buffer.removeAll()
        }

        var index = 0
        while index < lines.count {
            let line = lines[index]
            if let match = openRegex.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)) {
                flush()

                let indent = (line as NSString).substring(with: match.range(at: 1))
                let fence = (line as NSString).substring(with: match.range(at: 2))
                let langRaw = (line as NSString).substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespaces)
                let language = langRaw.isEmpty ? nil : langRaw

                var j = index + 1
                var codeLines: [String] = []

                func isFence(_ str: String) -> Bool {
                    str.trimmingCharacters(in: .whitespaces) == fence && str.hasPrefix(indent)
                }

                if j < lines.count && isFence(lines[j]) {
                    codeLines.append(lines[j])
                    j += 1
                }

                var closing: Int? = nil
                while j < lines.count {
                    if isFence(lines[j]) {
                        var first = j
                        j += 1
                        while j < lines.count && isFence(lines[j]) {
                            codeLines.append(lines[first])
                            first = j
                            j += 1
                        }
                        closing = j - 1
                        break
                    } else {
                        codeLines.append(lines[j])
                        j += 1
                    }
                }

                if let close = closing {
                    let code = codeLines.joined(separator: "\n")
                    let attachment = CodeBlockAttachment(code: code, language: language)
                    parts.append(NSAttributedString(attachment: attachment))
                    index = close + 1
                } else {
                    buffer.append(line)
                    buffer.append(contentsOf: codeLines)
                    index = j
                }
            } else {
                buffer.append(line)
                index += 1
            }
        }

        flush()

        let result = NSMutableAttributedString()
        parts.forEach { result.append($0) }
        while result.string.hasSuffix("\n") {
            result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
        }
        return result
    }

    private func parseInline(_ text: String) -> NSAttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        options.allowsExtendedAttributes = true

        if var attr = try? AttributedString(markdown: text, options: options) {
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
            return NSAttributedString(attr)
        } else {
            return NSAttributedString(string: text, attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ])
        }
    }

    private func parseLineWithImages(_ line: String) -> NSAttributedString {
        let ns = line as NSString
        let matches = imageRegex.matches(in: line, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else {
            return parseInline(line)
        }
        let result = NSMutableAttributedString()
        var location = 0
        for match in matches {
            if match.range.location > location {
                let textPart = ns.substring(with: NSRange(location: location, length: match.range.location - location))
                result.append(parseInline(textPart))
            }
            let alt = ns.substring(with: match.range(at: 1))
            let urlString = ns.substring(with: match.range(at: 2))
            if let url = URL(string: urlString) {
                let attachment = RemoteImageAttachment(url: url, altText: alt)
                result.append(NSAttributedString(attachment: attachment))
            } else {
                let raw = ns.substring(with: match.range)
                result.append(parseInline(raw))
            }
            location = match.range.location + match.range.length
        }
        if location < ns.length {
            let textPart = ns.substring(from: location)
            result.append(parseInline(textPart))
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

                let fontSize: CGFloat
                switch headingLevel {
                case 1: fontSize = 28
                case 2: fontSize = 24
                default: fontSize = 20
                }

                var attr = NSMutableAttributedString(attributedString: parseLineWithImages(content))
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
                result.append(parseLineWithImages(line))
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

            let bullet = NSAttributedString(
                string: "\u{2022} ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.label
                ]
            )
            result.append(bullet)
            result.append(parseLineWithImages(item))
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
            var numberText = "\(idx + 1). "
            if let range = item.range(of: "^\\d+\\. ", options: .regularExpression) {
                let prefix = item[item.startIndex..<range.upperBound]
                numberText = String(prefix)
                item = String(item[range.upperBound...])
            }

            let bullet = NSAttributedString(
                string: numberText,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.label
                ]
            )
            result.append(bullet)
            result.append(parseLineWithImages(item))
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
