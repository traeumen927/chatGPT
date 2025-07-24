import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class RemoteImageGroupView: UIView {
    enum Style {
        case horizontal
        case grid
    }

    private let collectionView: UICollectionView
    private let urls: [URL]
    let style: Style
    private let disposeBag = DisposeBag()

    init(urls: [URL], style: Style = .horizontal) {
        self.urls = urls
        self.style = style
        let layout: UICollectionViewFlowLayout
        switch style {
        case .horizontal:
            layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
        case .grid:
            layout = TrailingFlowLayout()
            layout.scrollDirection = .vertical
        }
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)
        self.layout()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        backgroundColor = ThemeColor.background1
        addSubview(collectionView)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = style == .horizontal
        collectionView.isScrollEnabled = style == .horizontal
        collectionView.register(RemoteImageCollectionCell.self, forCellWithReuseIdentifier: "RemoteImageCollectionCell")
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bind() {
        Observable.just(urls)
            .bind(to: collectionView.rx.items(cellIdentifier: "RemoteImageCollectionCell", cellType: RemoteImageCollectionCell.self)) { _, url, cell in
                cell.configure(url: url)
            }
            .disposed(by: disposeBag)

        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
}

extension RemoteImageGroupView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch style {
        case .horizontal:
            let width = collectionView.bounds.width * 0.65
            return CGSize(width: width, height: width)
        case .grid:
            let layout = collectionViewLayout as? UICollectionViewFlowLayout
            let spacing = layout?.minimumInteritemSpacing ?? 8
            let width = (collectionView.bounds.width - spacing * 2) / 3
            return CGSize(width: width, height: width)
        }
    }
}
