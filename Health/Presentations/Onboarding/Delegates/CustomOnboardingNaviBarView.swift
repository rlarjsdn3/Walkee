//
//  CustomNavigationBarViewDelegate.swift
//  Health
//
//  Created by 권도현 on 8/13/25.
//


import UIKit

/// 네비게이션 바 상단에 표시되는 커스텀 뷰
///
/// - 뒤로가기 버튼과 페이지 진행 상태를 나타내는 **ProgressIndicatorStackView**를 포함한다.
/// - 온보딩 화면 등 다단계 화면에서 현재 페이지 진행도를 표시하고, 뒤로가기 동작을 위임(delegate) 방식으로 전달한다.
protocol CustomNavigationBarViewDelegate: AnyObject {
    /// 뒤로가기 버튼이 탭 되었을 때 호출되는 메서드
    func backButtonTapped()
}

class CustomNavigationBarView: UIView {
    
    /// 뒤로가기 버튼 이벤트를 전달받을 델리게이트
    weak var delegate: CustomNavigationBarViewDelegate?
    
    /// 페이지 진행 상태를 표시하는 스택 뷰 (읽기 전용)
    private(set) var progressIndicatorStackView: ProgressIndicatorStackView
    
    /// 네비게이션 바 왼쪽에 위치하는 뒤로가기 버튼
    ///
    /// - SF Symbol `"chevron.left"` 아이콘을 사용
    /// - `pointSize: 14`, `weight: .semibold` 설정
    let backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    /// CustomNavigationBarView 초기화 메서드
    ///
    /// - Parameter totalPages: 전체 페이지 개수 (ProgressIndicatorStackView에 전달됨)
    init(totalPages: Int) {
        self.progressIndicatorStackView = ProgressIndicatorStackView(totalPages: totalPages)
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        backButton.addTarget(self, action: #selector(backButtonAction), for: .touchUpInside)
    }
    
    /// 뒤로가기 버튼 탭 이벤트 핸들러
    ///
    /// 델리게이트의 `backButtonTapped()` 메서드를 호출한다.
    @objc private func backButtonAction() {
        delegate?.backButtonTapped()
    }
    
    /// 서브뷰를 추가하고 기본 UI를 구성하는 메서드
    private func setupViews() {
        addSubview(backButton)
        addSubview(progressIndicatorStackView)
        progressIndicatorStackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    /// 오토레이아웃 제약 조건을 설정하는 메서드
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 30),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            progressIndicatorStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressIndicatorStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressIndicatorStackView.heightAnchor.constraint(equalToConstant: 4),
            progressIndicatorStackView.widthAnchor.constraint(equalToConstant: 300),
        ])
    }

    /// 스토리보드/인터페이스 빌더 초기화는 지원하지 않음
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
