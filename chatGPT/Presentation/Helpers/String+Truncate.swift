//
//  String+Truncate.swift
//  chatGPT
//
//  Created by 홍정연 on 6/17/25.
//

import Foundation

extension String {
    /// 문자열이 지정된 글자 수를 초과할 경우 뒷부분을 "…"으로 생략합니다.
    func truncated(limit: Int) -> String {
        guard self.count > limit else { return self }
        let index = self.index(self.startIndex, offsetBy: limit)
        return String(self[..<index]) + "…"
    }
}
