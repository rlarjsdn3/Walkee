//
//  WalkingFilterCell.swift
//  Health
//
//  Created by juks86 on 8/6/25.
//

import UIKit

class WalkingFilterCell: CoreCollectionViewCell {
    
    @IBOutlet weak var toggleButton: UIButton!
    
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
        print("🔧 setupPullDownMenu 호출됨")
        
        //  메뉴 선택 시 실행될 액션을 정의
        // 이 핸들러는 어떤 항목이 선택되었는지 확인하는 등 추가 로직이 필요할 때 유용합니다.
        let actionHandler: (UIAction) -> Void = { action in
            print("✅ '\(action.title)' 선택됨")
        }
        
        // 메뉴에 맞춰 액션을 생성.
        let actions = [
            UIAction(title: "가까운순", handler: actionHandler),
            UIAction(title: "코스길이순", handler: actionHandler)
        ]
        
        // 액션들로 메뉴를 생성.
        let menu = UIMenu(children: actions)
        
        // 버튼에 메뉴를 설정하고, 주요 속성들을 설정
        toggleButton.menu = menu
        toggleButton.showsMenuAsPrimaryAction = true
        
        //메뉴 항목 선택 시 버튼의 제목이 자동으로 변경
        toggleButton.changesSelectionAsPrimaryAction = true
        
    }
}

