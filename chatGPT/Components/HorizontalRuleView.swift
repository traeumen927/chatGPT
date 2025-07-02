import UIKit

final class HorizontalRuleView: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = .label
        autoresizingMask = [.flexibleWidth]
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 1 / UIScreen.main.scale)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
