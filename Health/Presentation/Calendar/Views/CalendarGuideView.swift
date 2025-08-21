import UIKit

final class CalendarGuideView: UIView {

    private struct Section {
        let title: String
        let description: String
    }

    private let sections: [Section] = [
        Section(
            title: "걸음 수 확인",
            description: "각 날짜 원에서 목표 대비 진행률을 확인할 수 있으며, 달성 시 색상으로 강조됩니다."
        ),
        Section(
            title: "대시보드 이동",
            description: "데이터가 있는 날짜를 선택해서 열리는 대시보드를 통해 상세 정보를 확인할 수 있습니다."
        ),
        Section(
            title: "데이터 출처",
            description: "걸음 수는 건강 앱과 동기화되며, 연동이 꺼져 있으면 표시되지 않습니다."
        )
    ]

	private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        setupStackView()
        setupConstraints()
        setupSections()
    }

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    private func setupSections() {
        sections.forEach { section in
            addSection(title: section.title, description: section.description)
        }
    }

    private func addSection(title: String, description: String) {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.text = title

        let descLabel = createDescriptionLabel(text: description)

        let vStack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        vStack.axis = .vertical
        vStack.spacing = 4

        stackView.addArrangedSubview(vStack)
    }

    private func createDescriptionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakStrategy = .hangulWordPriority

        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle: paragraphStyle
            ]
        )

        label.attributedText = attributedString
        return label
    }
}
