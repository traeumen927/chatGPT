import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class RemoteImageGroupView: UIView {
    private let urls: [URL]
    private let disposeBag = DisposeBag()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isScrollEnabled = false
        cv.backgroundColor = .clear
        return cv
    }()

    init(urls: [URL]) {
        self.urls = urls
        super.init(frame: .zero)
        layout()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        backgroundColor = ThemeColor.background1
        addSubview(collectionView)
        collectionView.register(RemoteImageCell.self, forCellWithReuseIdentifier: "RemoteImageCell")
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bind() {
        Observable.just(urls)
            .bind(to: collectionView.rx.items(cellIdentifier: "RemoteImageCell", cellType: RemoteImageCell.self)) { index, url, cell in
                cell.configure(url: url)
            }
            .disposed(by: disposeBag)
    }

    override var intrinsicContentSize: CGSize {
        collectionView.layoutIfNeeded()
        return collectionView.collectionViewLayout.collectionViewContentSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let size: CGFloat = 80
            layout.itemSize = CGSize(width: size, height: size)
        }
    }
}
