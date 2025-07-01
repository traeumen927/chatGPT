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
        
        for (index, lineSub) in lines.enumerated() {
            let line = String(lineSub)
            
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                let attachment = HorizontalRuleAttachment()
                result.append(NSAttributedString(attachment: attachment))
            } else {
                var options = AttributedString.MarkdownParsingOptions()
                options.interpretedSyntax = .inlineOnlyPreservingWhitespace
                options.allowsExtendedAttributes = true
                
                if var attr = try? AttributedString(markdown: line, options: options) {
                    
                    // run 단위 스타일 지정
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
                    // fallback: 마크다운 파싱 실패 시 일반 텍스트로 처리
                    result.append(NSAttributedString(string: line, attributes: [
                        .font: UIFont.systemFont(ofSize: 16),
                        .foregroundColor: UIColor.label
                    ]))
                }
            }
            
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        
        return result
    }
}
