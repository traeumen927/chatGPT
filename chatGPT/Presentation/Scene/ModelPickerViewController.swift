import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ModelPickerViewController: UIViewController {
    private let models: [OpenAIModel]
    private var selectedModel: OpenAIModel
    private let disposeBag = DisposeBag()

    var onSelect: ((OpenAIModel) -> Void)?

    private let pickerView = UIPickerView()
    private let toolbar = UIToolbar()

    init(models: [OpenAIModel], selected: OpenAIModel) {
        self.models = models
        self.selectedModel = selected
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout()
        bind()
    }

    private func layout() {
        view.backgroundColor = ThemeColor.background1

        [toolbar, pickerView].forEach(view.addSubview)

        toolbar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        pickerView.snp.makeConstraints { make in
            make.top.equalTo(toolbar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(216)
        }

        let cancel = UIBarButtonItem(title: "취소", style: .plain, target: nil, action: nil)
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "선택", style: .done, target: nil, action: nil)
        toolbar.setItems([cancel, flex, done], animated: false)

        pickerView.dataSource = self
        pickerView.delegate = self
        if let index = models.firstIndex(of: selectedModel) {
            pickerView.selectRow(index, inComponent: 0, animated: false)
        }

        cancel.rx.tap
            .bind { [weak self] in self?.dismiss(animated: true) }
            .disposed(by: disposeBag)

        done.rx.tap
            .bind { [weak self] in
                guard let self else { return }
                let index = self.pickerView.selectedRow(inComponent: 0)
                self.selectedModel = self.models[index]
                self.onSelect?(self.selectedModel)
                self.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func bind() { }
}

extension ModelPickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        models.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        models[row].displayName
    }
}
