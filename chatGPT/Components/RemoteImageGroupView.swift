import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class RemoteImageGroupView: UIView {
    private let collectionView: UICollectionView
    private let urls: [URL]
    private let disposeBag = DisposeBag()

    init(urls: [URL]) {
        self.urls = urls
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
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
        collectionView.showsHorizontalScrollIndicator = true
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
        let width = collectionView.bounds.width * 0.65
        return CGSize(width: width, height: width)
    }
}
