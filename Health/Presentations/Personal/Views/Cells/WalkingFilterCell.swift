//
//  WalkingFilterCell.swift
//  Health
//
//  Created by juks86 on 8/6/25.
//

import UIKit

class WalkingFilterCell: CoreCollectionViewCell {
    
    @IBOutlet weak var toggleButton: UIButton!
    
    var onFilterSelected: ((String) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        toggleButton.applyCornerStyle(.medium)
        setupPullDownMenu()
        
    }
    
    private func setupPullDownMenu() {
        
        // 메뉴 선택 시 실행될 액션
        let actionHandler: (UIAction) -> Void = { [weak self] action in
            
            // 비활성화된 항목은 선택되지 않도록 함
            guard action.attributes != .disabled else {
                return
            }
            
            // PersonalViewController에게 어떤 필터가 선택되었는지 알려줌
            self?.onFilterSelected?(action.title)
        }
        
        // 현재 위치 권한 상태 확인
        let isLocationGranted = LocationPermissionService.shared.checkCurrentPermissionStatus()
        
        // "코스 길이 순" 액션 (항상 활성화)
        let courseLengthAction = UIAction(title: "코스 길이 순", handler: actionHandler)
        
        // "가까운 순" 액션 (위치 권한에 따라 활성화/비활성화)
        let nearbyAction: UIAction
        if isLocationGranted {
            nearbyAction = UIAction(title: "가까운 순", handler: actionHandler)
        } else {
            nearbyAction = UIAction(title: "가까운 순", attributes: .disabled, handler: actionHandler)
        }
        
        // 액션들로 메뉴를 생성
        let actions = [courseLengthAction, nearbyAction]
        let menu = UIMenu(children: actions)
        
        // 버튼에 메뉴를 설정하고, 주요 속성들을 설정
        toggleButton.menu = menu
        toggleButton.showsMenuAsPrimaryAction = true
        
        // 메뉴 항목 선택 시 버튼의 제목이 자동으로 변경
        toggleButton.changesSelectionAsPrimaryAction = true
    }
    
    func updateLocationPermission(_ isGranted: Bool) {
        // 메뉴를 다시 설정해서 권한 상태에 맞게 업데이트
        setupPullDownMenu()
    }
}

