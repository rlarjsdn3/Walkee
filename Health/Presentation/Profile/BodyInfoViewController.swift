//
//  EditBodyInfoViewController.swift
//  Health
//
//  Created by 하재준 on 8/7/25.
//

import UIKit
import CoreData

struct BodyInfoItem {
    let iconName: String
    let title: String
    let detail: String
}

class EditBodyInfoViewController: CoreGradientViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private var items: [BodyInfoItem] = [
           .init(iconName: "figure.walk", title: "성별", detail: "남성"),
           .init(iconName: "birthday.cake", title: "태어난 해", detail: "1990"),
           .init(iconName: "scalemass", title: "무게", detail: "100kg"),
           .init(iconName: "ruler", title: "신체 사이즈", detail: "218cm")
       ]
    
    override func setupAttribute() {
        super.setupAttribute()
        
        applyBackgroundGradient(.midnightBlack)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "bodyInfoCell")
        tableView.backgroundColor = .clear
        tableView.separatorColor = .darkGray
    }

}

extension EditBodyInfoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bodyInfoCell", for: indexPath)
        let item = items[indexPath.row]
        
        var content = UIListContentConfiguration.valueCell()
        content.image            = UIImage(systemName: item.iconName)
        content.text             = item.title
        content.secondaryText    = item.detail
        content.secondaryTextProperties.color   = .systemGray
        
        cell.contentConfiguration = content
        cell.accessoryType        = .none
        cell.selectionStyle       = .none
        cell.backgroundColor      = .clear

        return cell
    }
}

extension EditBodyInfoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
