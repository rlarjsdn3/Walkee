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
    var iconName: String
    var title: String
    var detail: String
}

enum EditKind {
    case gender
    case height
    case weight
    case birthday
}

@MainActor
func presentSheet(on viewController: UIViewController,
                  height: CGFloat = 300,
                  buildView: () -> UIView,
                  onConfirm: ((UIView) -> Void)? = nil) {
    
    let contentView = buildView()
    contentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        contentView.heightAnchor.constraint(equalToConstant: height)
    ])
    
    let alertController = TSAlertController(
        contentView,
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
        onConfirm?(contentView)
    }
    alertController.addAction(action)
    
    viewController.present(alertController, animated: true)
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
        
        let title = items[indexPath.row].title
        
        switch title {
        case "성별":
            presentSheet(
                on: self,
                buildView: {
                    EditGenderView()
                }) { [weak self] view in
                guard let self, let v = view as? EditGenderView else { return }
                self.items[indexPath.row].detail = "\(v.selectedGender)"
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        case "태어난 해":
            presentSheet(
                on: self,
                buildView: {
                    EditBirthdayView()
                }) { [weak self] view in
                guard let self, let v = view as? EditBirthdayView else { return }
                self.items[indexPath.row].detail = "\(v.getSelectedYear())"
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        case "무게":
            presentSheet(
                on: self,
                buildView: {
                    EditWeightView()
                }) { [weak self] view in
                guard let self, let v = view as? EditWeightView else { return }
                self.items[indexPath.row].detail = "\(v.selectedWeight)kg"
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        case "신체 사이즈":
            presentSheet(
                on: self,
                buildView: {
                    EditHeightView()
                }) { [weak self] view in
                guard let self, let v = view as? EditHeightView else { return }
                self.items[indexPath.row].detail = "\(v.selectedHeight)cm"
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        default:
            break
        }
    }
}
