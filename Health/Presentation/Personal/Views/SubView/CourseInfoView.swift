//
//  CourseInfoView.swift
//  Health
//
//  Created by juks86 on 8/21/25.
//

import UIKit

final class CourseInfoView: UIView {

    // GuideView.Configuration과 동기화
    struct Constants {
        static let titleFont: UIFont = .preferredFont(forTextStyle: .headline)
        static let descriptionFont: UIFont = .preferredFont(forTextStyle: .body)
        static let titleColor: UIColor = .label
        static let descritionColor: UIColor = .secondaryLabel
        static let contentSpacing: CGFloat = 4
        static let sectionSpacing: CGFloat = 16
        static let margin: CGFloat = 8
    }

    private let stackView = UIStackView()

    var course: WalkingCourse? = nil {
        didSet { self.setNeedsLayout() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear

        addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = Constants.sectionSpacing
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.margin),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.margin),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.margin),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.margin)
        ])
    }

    override func layoutSubviews() {
         super.layoutSubviews()

         // 기존 뷰들 제거
         stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

         guard let course = course else { return }

         // 코스 설명 섹션
         if !course.crsContents.isEmpty {
             let cleanContent = course.crsSummary.replacingOccurrences(of: "<br>", with: "\n")
             let sectionView = createInfoSection(title: "코스 설명", content: cleanContent)
             stackView.addArrangedSubview(sectionView)
         }

         // 관광 정보 섹션
         if !course.crsTourInfo.isEmpty {
             let cleanContent = course.crsTourInfo.replacingOccurrences(of: "<br>", with: "\n")
             let sectionView = createInfoSection(title: "관광 정보", content: cleanContent)
             stackView.addArrangedSubview(sectionView)
         }

        let messageLabel = UILabel()
        messageLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        messageLabel.textColor = .warningSymbol
        messageLabel.text = "코스난이도는 사용자의 신체정보를 바탕으로 추천됩니다."
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        stackView.addArrangedSubview(messageLabel)
     }

    private func createInfoSection(title: String, content: String) -> UIView {
        let containerView = UIView()

        let titleLabel = UILabel()
        titleLabel.font = Constants.titleFont
        titleLabel.textColor = Constants.titleColor
        titleLabel.text = title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let contentLabel = UILabel()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakStrategy = .hangulWordPriority

        let attributedString = NSAttributedString(
            string: content,
            attributes: [
                .font: Constants.descriptionFont,
                .foregroundColor: Constants.descritionColor,
                .paragraphStyle: paragraphStyle
            ]
        )

        contentLabel.attributedText = attributedString
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(titleLabel)
        containerView.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Constants.contentSpacing),
            contentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }
}
