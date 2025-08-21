//
//  CourseInfoView.swift
//  Health
//
//  Created by juks86 on 8/21/25.
//

import UIKit

final class CourseInfoView: UIView {

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
        backgroundColor = .systemBackground

        addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
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
        messageLabel.text = "코스난이도는 사용자의 신체정보를 바탕으로 추천됩니다"
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 1
        stackView.addArrangedSubview(messageLabel)
     }

    private func createInfoSection(title: String, content: String) -> UIView {
        let containerView = UIView()

        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.text = title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let contentLabel = UILabel()
        contentLabel.font = UIFont.preferredFont(forTextStyle: .body)
        contentLabel.textColor = .secondaryLabel
        contentLabel.text = content
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(titleLabel)
        containerView.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            contentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }
}
