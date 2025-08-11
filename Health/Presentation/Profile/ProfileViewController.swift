//
//  ProfileViewController.swift
//  Health
//
//  Created by 하재준 on 8/1/25.
//

import UIKit

struct ProfileCellModel {
    let title: String
    let iconName: String
    let isSwitch: Bool
    var switchState: Bool = false
}

class ProfileViewController: CoreGradientViewController {
        
    @IBOutlet weak var tableView: UITableView!
    
    private let sectionTitles: [String?] = [
        nil,
        "개인 설정",
        "권한 설정"
    ]
    
    private var sectionItems: [[ProfileCellModel]] = [
        [ProfileCellModel(
            title: "신체 정보",
            iconName: "person.fill",
            isSwitch: false
        )
        ],
        [ProfileCellModel(
            title: "목표 걸음 설정",
            iconName: "figure.walk",
            isSwitch: false
        ),
         ProfileCellModel(
            title: "일반 설정",
            iconName: "gearshape.fill",
            isSwitch: false
         )
        ],
        [ProfileCellModel(
            title: "Apple 건강 앱",
            iconName: "applelogo",
            isSwitch: true,
            switchState: true
        )
        ]
    ]
    
    override func setupAttribute() {
        super.setupAttribute()
        
        applyBackgroundGradient(.midnightBlack)
        
        navigationItem.title = "프로필"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "profileCell")
        tableView.rowHeight = 68
        tableView.backgroundColor = .clear
    }
    
    @objc private func switchChanged(_ sender: UISwitch) {
        print("Apple 건강 앱 권한 상태:", sender.isOn)
        sectionItems[sender.tag][0].switchState = sender.isOn
    }
    
}

extension ProfileViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionItems.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath)
        let model = sectionItems[indexPath.section][indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.image = UIImage(systemName: model.iconName)
        content.text = model.title
        content.imageProperties.tintColor = .systemGray
        
        cell.contentConfiguration = content
        cell.backgroundColor = UIColor.buttonText.withAlphaComponent(0.1)
        
        let bgView = UIView()
        bgView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        cell.selectedBackgroundView = bgView
        cell.selectionStyle = .default
        
        if model.isSwitch {
            let toggle = UISwitch(frame: .zero)
            toggle.isOn = model.switchState
            toggle.tag = indexPath.section
            toggle.onTintColor = .accent
            toggle.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
        } else {
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        
        return cell
    }
    
}
extension ProfileViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = sectionItems[indexPath.section][indexPath.row]
        
        switch model.title {
        case "신체 정보":
            performSegue(withIdentifier: "bodyInfo", sender: nil)
        case "목표 걸음 설정":
            break
        case "일반 설정":
            break
        default:
            break
        }
    }
}
