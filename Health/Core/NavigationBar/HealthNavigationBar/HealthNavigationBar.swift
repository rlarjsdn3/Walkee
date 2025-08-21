//
//  HealthNavigationBar.swift
//  HealthNavigationBarProject
//
//  Created by 김건우 on 8/19/25.
//

import UIKit

final class HealthNavigationBar: CoreView {

    private let titleImageView = UIImageView()
    private let titleLabel = UILabel()
    private let titleStackView = UIStackView()
    private let titleContainerView = UIView()

    private let backButton = UIButton(type: .system)
    private let centerTitleLabel = UILabel()
    private let backContainerView = UIView()

    private let trailingBarItemsStackView = UIStackView()
    
    private let divider = UIView()

    private var chevronLeftImage: UIImage? = {
        var image = UIImage(systemName: "chevron.left")
        let config1 = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let config2 = UIImage.SymbolConfiguration(paletteColors: [.label])
        return image?.applyingSymbolConfiguration(config1)?
            .applyingSymbolConfiguration(config2)
    }()

    private let defaultTitleImageSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22)

    private var defaultTrailingBarButtonItemSymbolConfiguration: UIImage.SymbolConfiguration {
        isPad
        ? UIImage.SymbolConfiguration(pointSize: 24)
        : UIImage.SymbolConfiguration(pointSize: 20)
    }

    /// 내비게이션 바의 동작을 위임받을 델리게이트입니다.
    weak var delegate: (any HealthNavigationBarDelegate)?

    /// 내비게이션 바의 기본 제목입니다.
    var title: String? = "Swift" {
        didSet { updateNavigationBarAttributes() }
    }

    /// 기본 제목에 적용할 폰트입니다.
    var titleFont: UIFont = .systemFont(ofSize: 22, weight: .semibold) {
        didSet { updateNavigationBarAttributes() }
    }

    /// 중앙 제목에 적용할 폰트입니다.
    var centerTitleFont: UIFont = .systemFont(ofSize: 17, weight: .semibold) {
        didSet { updateNavigationBarAttributes() }
    }

    /// 제목 옆에 표시할 이미지입니다.
    var titleImage: UIImage? = UIImage(systemName: "swift") {
        didSet { updateNavigationBarAttributes() }
    }

    /// 제목 이미지에 적용할 심볼 구성 설정입니다.
    ///
    /// SFSymbol의 크기는 24pt로 고정되며, 변경할 수 없습니다.
    /// 일반 이미지에는 적용되지 않습니다.
    var preferredTitleImageSymbolConfiguration: UIImage.SymbolConfiguration? = nil {
        didSet { updateNavigationBarAttributes() }
    }

    /// 바 버튼 아이템에 적용할 심볼 구성 설정입니다.
    ///
    /// SFSymbol의 크기는 아이폰에서 20pt, 아이패드에서 24pt로 고정되며 변경할 수 없습니다.
    /// 일반 이미지에는 적용되지 않습니다.
    var preferredTrailingBarButtonItemSymbolConfiguration: UIImage.SymbolConfiguration? = nil {
        didSet { self.setNeedsLayout() }
    }

    /// 내비게이션 바 오른쪽에 표시할 버튼 아이템 배열입니다.
    var trailingBarButtonItems: [HealthBarButtonItem]? = nil {
        didSet { self.setNeedsLayout() }
    }

    /// 오른쪽 버튼 아이템 간 간격입니다.
    var trailingBarButtonItemSpacing: CGFloat = 16 {
        didSet { self.setNeedsLayout() }
    }

    /// 제목 레이블의 숨김 여부입니다.
    var isTitleLabelHidden: Bool = false {
        didSet { updateNavigationBarAttributes() }
    }

    /// 아이패드 환경에서 제목 레이블의 숨김 여부를 제어합니다.
    ///
    /// - `true`: `isTitleLabelHidden` 값과 관계없이 제목 레이블이 항상 숨겨집니다.
    /// - `false`: 제목 레이블의 표시 여부가 `isTitleLabelHidden` 값에 따라 결정됩니다.
    ///
    /// 이 프로퍼티는 아이패드 환경에서만 적용됩니다.
    var alwaysHiddenTitleLabelOnIPad: Bool = true {
        didSet { updateNavigationBarAttributes() }
    }

    /// 뒤로 가기 버튼의 숨김 여부입니다.
    var isBackButtonHidden: Bool = false {
        didSet { updateNavigationBarAttributes() }
    }

    /// 구분선의 숨김 여부입니다.
    var isDividerHidden: Bool = false {
        didSet { updateNavigationBarAttributes() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        trailingBarItemsStackView.spacing = trailingBarButtonItemSpacing

        guard let vc = firstAvailableViewController else { return }
        layoutNavigationBar(vc, nav: vc.navigationController)

        guard let items = trailingBarButtonItems else { return }
        trailingBarItemsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        layoutTrailingBarButtonItems(items)
        print(trailingBarItemsStackView.bounds.height)
    }

    private func layoutNavigationBar(_ vc: UIViewController, nav: UINavigationController?) {
        // 네비게이션 컨트롤러에 임베드되어 있지 않거나,
        guard let index = nav?.viewControllers.firstIndex(of: vc) else {
            showTopMostNavigationBarElements()
            return
        }

        // 뷰-컨트롤러가 스택 최하단에 위치한다면
        if index == 0 { showTopMostNavigationBarElements() }
        // 뷰-컨트롤러가 스택 최하단이 아닌 다른 곳에 위치한다면
        else { showNestedNavigationBarElements() }
    }

    private func layoutTrailingBarButtonItems(_ items: [HealthBarButtonItem]) {
        items.enumerated().forEach { offset, item in
            let button = makeButton(with: item)
            trailingBarItemsStackView.addArrangedSubview(button)
        }
    }

    private func makeButton(with item: HealthBarButtonItem) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = item.title
        config.image = item.image
        config.preferredSymbolConfigurationForImage = defaultTrailingBarButtonItemSymbolConfiguration
            .applying(preferredTrailingBarButtonItemSymbolConfiguration ?? defaultTrailingBarButtonItemSymbolConfiguration)
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        let button = UIButton(configuration: config)
        if let primaryAction = item.primaryAction {
            button.addAction(UIAction(handler: { _ in
                primaryAction()
            }), for: .touchUpInside)
        }
        configureButtonUpdateHandler(button)

        return button
    }

    override func setupHierarchy() {
        addSubview(titleContainerView)
        titleContainerView.addSubview(titleStackView)
        titleStackView.addArrangedSubviews(titleImageView, titleLabel)

        addSubview(backContainerView)
        backContainerView.addSubviews(backButton, centerTitleLabel)

        addSubview(trailingBarItemsStackView)
        addSubview(divider)
    }

    override func setupAttribute() {
        backgroundColor = .clear

        titleImageView.image = UIImage(systemName: "swift")
        titleImageView.contentMode = .scaleAspectFit
        titleImageView.tintColor = .accent

        titleLabel.textColor = .label

        titleStackView.spacing = 8
        titleStackView.alignment = .fill
        titleStackView.translatesAutoresizingMaskIntoConstraints = false

        titleContainerView.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.plain()
        config.image = chevronLeftImage
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 16)
        backButton.configuration = config
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        configureButtonUpdateHandler(backButton)

        centerTitleLabel.textColor = .label
        centerTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        backContainerView.translatesAutoresizingMaskIntoConstraints = false

        trailingBarItemsStackView.distribution = .fill
        trailingBarItemsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        divider.backgroundColor = .boxBg
        divider.translatesAutoresizingMaskIntoConstraints = false

        updateNavigationBarAttributes()
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            titleStackView.topAnchor.constraint(equalTo: titleContainerView.topAnchor),
            titleStackView.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor),
            titleStackView.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor),

            titleContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleContainerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            titleContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            titleContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18)
        ])

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: backContainerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: backContainerView.centerYAnchor),

            centerTitleLabel.centerXAnchor.constraint(equalTo: backContainerView.centerXAnchor),
            centerTitleLabel.centerYAnchor.constraint(equalTo: backContainerView.centerYAnchor),

            backContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            backContainerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            backContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            backContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18)
        ])

        NSLayoutConstraint.activate([
            trailingBarItemsStackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            trailingBarItemsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            trailingBarItemsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
        
        NSLayoutConstraint.activate([
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])

        let bottomConstant: CGFloat = isPad ? 13 : 0
        divider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomConstant).isActive = true
    }

    private func updateNavigationBarAttributes() {
        titleLabel.text = title
        centerTitleLabel.text = title

        titleLabel.font = titleFont
        centerTitleLabel.font = centerTitleFont

        titleImageView.image = titleImage?
            .applyingSymbolConfiguration(preferredTitleImageSymbolConfiguration ?? defaultTitleImageSymbolConfiguration)?
            .applyingSymbolConfiguration(defaultTitleImageSymbolConfiguration)

        trailingBarItemsStackView.spacing = trailingBarButtonItemSpacing

        titleStackView.isHidden = shouldHiddenTitleLabel
        centerTitleLabel.isHidden = shouldHiddenTitleLabel
        backButton.isHidden = isBackButtonHidden
        divider.isHidden = isDividerHidden
    }

    var shouldHiddenTitleLabel: Bool {
        return isPad
        ? alwaysHiddenTitleLabelOnIPad || isTitleLabelHidden
        : isTitleLabelHidden
    }

    private func configureButtonUpdateHandler(_ button: UIButton) {
        button.configurationUpdateHandler = { button in
            switch button.state {
            case .highlighted: button.alpha = 0.5
            default: button.alpha = 1
            }
        }
    }

    @objc private func backButtonTapped(_ sender: UIButton) {
        if delegate != nil { delegate?.navigationBar(didTapBackButton: sender) }
        else { firstAvailableViewController?.navigationController?.popViewController(animated: true) }
    }
}

extension HealthNavigationBar {

    /// 스크롤 위치에 따라 제목 레이블의 표시 여부를 결정합니다.
    ///
    /// `scrollView`의 세로 오프셋(`contentOffset.y + contentInset.top`)이
    /// `anchorOffsetY`보다 크면 제목 레이블과 중앙 제목 레이블을 표시합니다.
    /// 반대로 기준 이하일 경우에는 숨깁니다.
    ///
    /// - Parameters:
    ///   - scrollView: 스크롤 위치를 기준으로 사용할 `UIScrollView` 인스턴스.
    ///   - anchorOffsetY: 제목을 표시하기 위한 Y 오프셋 기준 값.
    func shouldShowTitieLabel(_ scrollView: UIScrollView, greaterThan anchorOffsetY: CGFloat) {
        let offsetY = scrollView.contentOffset.y + scrollView.contentInset.top
        titleStackView.isHidden = offsetY <= anchorOffsetY
        centerTitleLabel.isHidden = offsetY <= anchorOffsetY
    }

    /// 스크롤 위치에 따라 구분선(divider)의 표시 여부를 결정합니다.
    ///
    /// `scrollView`의 세로 오프셋(`contentOffset.y + contentInset.top`)이
    /// `anchorOffsetY`보다 크면 구분선을 표시합니다.
    /// 반대로 기준 이하일 경우에는 숨깁니다.
    ///
    /// - Parameters:
    ///   - scrollView: 스크롤 위치를 기준으로 사용할 `UIScrollView` 인스턴스.
    ///   - anchorOffsetY: 구분선을 표시하기 위한 Y 오프셋 기준 값.
    func shouldShowDivider(_ scrollView: UIScrollView, greaterThan anchorOffsetY: CGFloat) {
        let offsetY = scrollView.contentOffset.y + scrollView.contentInset.top
        divider.isHidden = offsetY <= anchorOffsetY
    }
}

fileprivate extension HealthNavigationBar {

    func showTopMostNavigationBarElements() {
        titleContainerView.isHidden = false
        backContainerView.isHidden = true
    }

    func showNestedNavigationBarElements() {
        titleContainerView.isHidden = true
        backContainerView.isHidden = false
    }
}
