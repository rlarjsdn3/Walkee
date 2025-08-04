//
//  Layout+String.swift
//  Health
//
//  Created by 김건우 on 8/1/25.
//

import UIKit

typealias UICollectionViewConstant = UICollectionView.Constant
extension UICollectionView {

    struct Constant {

        /// 문자열을 표시할 때 사용할 기본 여백 값입니다.
        ///
        /// 일반적으로 텍스트 주변에 적용되는 좌우 마진 또는 패딩으로 사용되며,
        /// UI 디자인 가이드에 따라 기본값은 16pt로 설정되어 있습니다.
        static let defaultInset: CGFloat = 16.0

        /// 컬렉션뷰 아이템들 사이의 기본 간격입니다.
        ///
        /// 아이템과 아이템 사이, 또는 아이템과 컨테이너 경계 사이의
        /// 기본 여백으로 사용됩니다.
        static let defaultItemInset: CGFloat = 10.0

        // MARK: - 화면별 상단 제약 조건
        // 각 화면의 특성에 맞게 상단 여백을 다르게 설정합니다

        /// 온보딩 화면의 상단 여백입니다.
        ///
        /// 온보딩은 사용자가 처음 보는 화면이므로,
        /// 상대적으로 적은 여백으로 더 많은 내용을 보여줍니다.
        static let onboardingTopConstraint: CGFloat = 45.0

        /// 탐험 화면의 상단 여백입니다.
        ///
        /// 탐험 화면은 다양한 콘텐츠를 보여주는 메인 화면이므로,
        /// 넉넉한 상단 여백으로 시각적 여유를 줍니다.
        static let exploreTopConstraint: CGFloat = 100.0

        /// 달력 화면의 상단 여백입니다.
        ///
        /// 달력은 날짜 정보를 명확하게 보여주는 것이 중요하므로,
        /// 적당한 여백으로 깔끔한 레이아웃을 만듭니다.
        static let calendarTopConstraint: CGFloat = 64.0

        /// 맞춤 화면의 상단 여백입니다.
        ///
        /// 개인화된 설정 화면으로, 달력과 동일한 여백을 사용해
        /// 일관된 사용자 경험을 제공합니다.
        static let customTopConstraint: CGFloat = 64.0

        /// 프로필 화면의 상단 여백입니다.
        ///
        /// 사용자 정보를 보여주는 화면으로, 다른 설정 화면들과
        /// 동일한 여백을 사용해 통일성을 유지합니다.
        static let profileTopConstraint: CGFloat = 64.0
    }
}

// MARK: - 사용 예시
/*
 이렇게 정의한 상수들을 실제로 어떻게 사용하는지 예시입니다:

 // 컬렉션뷰 레이아웃 설정 시
 let layout = UICollectionViewFlowLayout()
 layout.sectionInset = UIEdgeInsets(
 top: UICollectionViewConstant.defaultItemInset,
 left: UICollectionViewConstant.defaultItemInset,
 bottom: UICollectionViewConstant.defaultItemInset,
 right: UICollectionViewConstant.defaultItemInset
 )

 // 뷰 컨트롤러에서 상단 제약 설정 시
 collectionViewTopConstraint.constant = UICollectionViewConstant.exploreTopConstraint

 // 또는 직접 접근해서 사용
 someView.leadingAnchor.constraint(
 equalTo: parentView.leadingAnchor,
 constant: UICollectionView.Constant.defaultInset
 ).isActive = true
 */

