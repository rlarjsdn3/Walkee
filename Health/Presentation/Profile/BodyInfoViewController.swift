//
//  BodyInfoViewController.swift
//  Health
//
//  Created by 하재준 on 8/7/25.
//

import UIKit
import CoreData
import TSAlertController

struct BodyInfoItem {
    let iconName: String
    let title: String
    let detail: String
}

enum EditKind {
    case gender
    case height
    case weight
    case birthday
}

class BodyInfoViewController: CoreGradientViewController {
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
        tableView.rowHeight = 68

    }
    
    func presentEditSheet() {
        let view = EditStepGoalView()
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        let alertController = TSAlertController(
            view,
            options: [.interactiveScaleAndDrag, .dismissOnTapOutside],
            preferredStyle: .actionSheet
        )
        
        alertController.configuration.prefersGrabberVisible = false
        alertController.configuration.enteringTransition = .slideUp
        alertController.configuration.exitingTransition = .slideDown
        alertController.configuration.headerAnimation = .slideUp
        alertController.configuration.buttonGroupAnimation = .slideUp
        alertController.viewConfiguration.spacing.keyboardSpacing = 100
        
        let action = TSAlertAction(title: "확인", style: .default) { _ in
            print("확인")
        }
        alertController.addAction(action)
        
        present(alertController, animated: true)
    }

}

extension BodyInfoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bodyInfoCell", for: indexPath)
        let item = items[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.image = UIImage(systemName: item.iconName)
        content.text = item.title
        content.imageProperties.tintColor = .systemGray
        content.secondaryText = item.detail
        content.secondaryTextProperties.color = .systemGray
        
        cell.contentConfiguration = content
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.buttonText.withAlphaComponent(0.1)

        return cell
    }
}

extension BodyInfoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        presentEditSheet()
    }
}
