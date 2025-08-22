import UIKit

/// 가이드 섹션의 제목과 설명을 담는 구조체
///
/// 각 가이드 섹션은 제목과 상세 설명으로 구성됩니다.
struct GuideSection {
    let title: String
    let description: String
}

/// 여러 가이드 섹션을 수직으로 표시하는 범용 가이드 뷰
///
/// `GuideView`는 제목과 설명으로 구성된 여러 섹션을 세로로 나열하여 표시하는 뷰입니다.
/// 바텀 시트, 모달, 또는 일반 화면에서 사용자에게 기능 안내나 도움말을 제공할 때 사용합니다.
final class GuideView: UIView {

    /// 가이드 뷰의 외관과 레이아웃을 설정하는 구조체
    ///
    /// 폰트, 색상, 간격, 여백 등 가이드 뷰의 모든 시각적 요소를 커스터마이징할 수 있습니다.
    struct Configuration {
        let titleFont: UIFont
        let descriptionFont: UIFont
        let titleColor: UIColor
        let descriptionColor: UIColor
        let contentSpacing: CGFloat
        let sectionSpacing: CGFloat
        let margins: UIEdgeInsets

        static let `default` = Configuration(
            titleFont: .preferredFont(forTextStyle: .headline),
            descriptionFont: .preferredFont(forTextStyle: .body),
            titleColor: .label,
            descriptionColor: .secondaryLabel,
            contentSpacing: 4,
            sectionSpacing: 16,
            margins: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        )
    }

    /// 현재 설정된 외관 구성
    private let configuration: Configuration

    /// 모든 섹션을 담는 스택 뷰
    private let stackView = UIStackView()

    /// 현재 표시 중인 가이드 섹션들
    private var guideSections: [GuideSection] = []

    convenience init() {
        self.init(configuration: .default)
    }

    init(configuration: Configuration = .default) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupView()
    }

    override init(frame: CGRect) {
        self.configuration = .default
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        self.configuration = .default
        super.init(coder: coder)
        setupView()
    }

    /// 가이드 섹션들을 설정하고 화면에 표시합니다.
    ///
    /// 기존에 표시되던 섹션들은 모두 제거되고 새로운 섹션들로 교체됩니다.
    ///
    /// - Parameter sections: 표시할 가이드 섹션 배열
    func configure(with sections: [GuideSection]) {
        self.guideSections = sections

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guideSections.forEach { section in
            addSection(title: section.title, description: section.description)
        }
    }
}

// MARK: - Private Methods
private extension GuideView {

    /// 뷰의 초기 설정을 수행합니다.
    func setupView() {
        setupStackView()
        setupConstraints()
    }

    /// 스택 뷰의 속성을 설정합니다.
    func setupStackView() {
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = configuration.sectionSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
    }

    /// 스택 뷰의 오토레이아웃 제약조건을 설정합니다.
    func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: configuration.margins.top),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: configuration.margins.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -configuration.margins.right),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -configuration.margins.bottom)
        ])
    }

    /// 개별 섹션을 스택 뷰에 추가합니다.
    /// - Parameters:
    ///   - title: 섹션의 제목
    ///   - description: 섹션의 설명
    func addSection(title: String, description: String) {
        let titleLabel = createTitleLabel(text: title)
        let descLabel = createDescriptionLabel(text: description)

        let vStack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        vStack.axis = .vertical
        vStack.spacing = configuration.contentSpacing

        stackView.addArrangedSubview(vStack)
    }

    /// 제목 레이블을 생성합니다.
    /// - Parameter text: 제목 텍스트
    /// - Returns: 설정된 제목 레이블
    func createTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = configuration.titleFont
        label.textColor = configuration.titleColor
        label.numberOfLines = 0
        label.text = text
        return label
    }

    /// 설명 레이블을 생성합니다.
    ///
    /// 한글 텍스트의 자연스러운 줄바꿈을 위해 `hangulWordPriority` 전략을 사용합니다.
    ///
    /// - Parameter text: 설명 텍스트
    /// - Returns: 설정된 설명 레이블
    func createDescriptionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakStrategy = .hangulWordPriority

        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: configuration.descriptionFont,
                .foregroundColor: configuration.descriptionColor,
                .paragraphStyle: paragraphStyle
            ]
        )

        label.attributedText = attributedString
        return label
    }
}

// MARK: - Factory Methods
extension GuideView {

    /// 지정된 섹션들로 구성된 가이드 뷰를 생성합니다.
    ///
    /// 섹션 배열과 선택적 설정을 받아 즉시 사용 가능한 GuideView를 반환합니다.
    ///
    /// ```swift
    /// let sections = [
    ///     GuideSection(title: "기능 1", description: "기능 1에 대한 설명"),
    ///     GuideSection(title: "기능 2", description: "기능 2에 대한 설명")
    /// ]
    /// let guideView = GuideView.create(with: sections)
    /// ```
    ///
    /// - Parameters:
    ///   - sections: 표시할 가이드 섹션 배열
    ///   - configuration: 가이드 뷰의 외관 설정. 기본값은 `.default`입니다.
    /// - Returns: 지정된 섹션들이 설정된 GuideView 인스턴스
    static func create(
        with sections: [GuideSection],
        configuration: Configuration = .default
    ) -> GuideView {
        let guideView = GuideView(configuration: configuration)
        guideView.configure(with: sections)
        return guideView
    }
}
