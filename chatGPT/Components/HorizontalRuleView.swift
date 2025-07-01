import UIKit

final class HorizontalRuleView: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = ThemeColor.label2
        autoresizingMask = [.flexibleWidth]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
