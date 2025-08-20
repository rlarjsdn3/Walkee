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
    action.configuration.backgroundColor = .accent
    action.configuration.titleAttributes = [
        .font: UIFont.preferredFont(forTextStyle: .headline),
        .foregroundColor: UIColor.systemBackground
    ]
    action.highlightType = .fadeIn
    
    alertController.addAction(action)
    
    viewController.present(alertController, animated: true)
}

class BodyInfoViewController: CoreGradientViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @Injected private var userVM: UserInfoViewModel
    
    private var currentUser: UserInfoEntity?
    
    private var items: [BodyInfoItem] = [
        .init(iconName: "figure.walk", title: "성별", detail: "-"),
        .init(iconName: "birthday.cake", title: "태어난 해", detail: "-"),
        .init(iconName: "scalemass", title: "체중", detail: "-"),
        .init(iconName: "ruler", title: "키", detail: "-")
    ]
    
    override func setupAttribute() {
        super.setupAttribute()
        
        applyBackgroundGradient(.midnightBlack)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "bodyInfoCell")
        tableView.backgroundColor = .clear
        tableView.rowHeight = 68
        
        fetchUserInfoAndSetupUI()
    }
    
    private func fetchUserInfoAndSetupUI() {
        userVM.fetchUsers()
        currentUser = userVM.users.first
        if let u = currentUser {
            let genderText = (u.gender ?? "").isEmpty ? "-" : (u.gender ?? "")
            if items.indices.contains(0) {
                items[0].detail = genderText
            }
            
            if items.indices.contains(1) {
                let age = Int(u.age)
                if age > 0 {
                    let year = Calendar.current.component(.year, from: Date()) - age
                    items[1].detail = "\(year)"
                } else {
                    items[1].detail = "-"
                }
            }
            
            if items.indices.contains(2), u.weight > 0 {
                items[2].detail = "\(Int(u.weight))kg"
            }
            
            if items.indices.contains(3), u.height > 0 {
                items[3].detail = "\(Int(u.height))cm"
            }
        }
        
        tableView.reloadData()
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
        content.textProperties.color = .systemGray
        content.imageProperties.tintColor = .systemGray
        cell.contentConfiguration = content
        
        let detailLabel = UILabel()
        detailLabel.text = item.detail
        detailLabel.textColor = .label
        detailLabel.sizeToFit()
        
        cell.accessoryView = detailLabel
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
            let currentGender: EditGenderView.Gender? = {
                switch items[indexPath.row].detail {
                case EditGenderView.Gender.female.rawValue:
                    return .female
                case EditGenderView.Gender.male.rawValue:
                    return .male
                default:
                    return nil
                }
            }()
            
            presentSheet(
                on: self,
                buildView: {
                    let v = EditGenderView()
                    v.setDefaultGender(currentGender)
                    return v
                }) { [weak self] view in
                    guard let self, let v = view as? EditGenderView else { return }
                    guard let selected = v.selectedGender else { return }
                    let u = self.currentUser
                    self.userVM.saveUser(
                        age: u?.age ?? 0,
                        gender: selected.rawValue,
                        height: u?.height ?? 0,
                        weight: u?.weight ?? 0,
                        diseases: u?.diseases as? [Disease]
                    )
                    self.fetchUserInfoAndSetupUI()
                }
        case "태어난 해":
            let currentYear = Calendar.current.component(.year, from: Date())
            let cellYear: Int? = {
                let digits = items[indexPath.row].detail.filter(\.isNumber)
                let y = Int(digits)
                return (y ?? 0) > 0 ? y : nil
            }()
            let defaultYear = cellYear ?? currentYear
            
            presentSheet(
                on: self,
                buildView: {
                    let v = EditBirthdayView()
                    v.setDefaultYear(defaultYear)
                    return v
                }) { [weak self] view in
                    guard let self, let v = view as? EditBirthdayView else { return }
                    
                    let selectedYear = v.getSelectedYear()
                    let age = currentYear - selectedYear
                    let u = self.currentUser
                    
                    self.userVM.saveUser(
                        id: u?.id,
                        age: Int16(age),
                        gender: u?.gender ?? "",
                        height: u?.height ?? 0,
                        weight: u?.weight ?? 0,
                        diseases: u?.diseases as? [Disease],
                        createdAt: u?.createdAt ?? Date()
                    )
                    
                    if self.items.indices.contains(indexPath.row) {
                        self.items[indexPath.row].detail = "\(selectedYear)"
                    }
                    self.fetchUserInfoAndSetupUI()
                    
                    
                }
        case "체중":
            let userWeight = currentUser?.weight ?? 0
            let cellWeight: Int = {
                let t = items[indexPath.row].detail
                let digits = t.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                return Int(digits) ?? 70
            }()
            let defaultWeight = userWeight > 0 ? Int(userWeight) : cellWeight
            
            
            presentSheet(
                on: self,
                buildView: {
                    let v = EditWeightView()
                    v.setDefaultWeight(defaultWeight)
                    return v
                }) { [weak self] view in
                    guard let self, let v = view as? EditWeightView else { return }
                    let newWeight = v.selectedWeight
                    let u = self.currentUser
                                        
                    self.userVM.saveUser(
                        age: u?.age ?? 0,
                        gender: u?.gender ?? "",
                        height: u?.height ?? 0,
                        weight: Double(newWeight),
                        diseases: u?.diseases as? [Disease]
                    )
                    
                    if self.items.indices.contains(indexPath.row) {
                        self.items[indexPath.row].detail = "\(Int(newWeight))kg"
                    }
                    self.fetchUserInfoAndSetupUI()
                }
        case "키":
            let userHeight = currentUser?.height ?? 0
            let cellHeight: Int = {
                let t = items[indexPath.row].detail
                let digits = t.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                return Int(digits) ?? 170
            }()
            let defaultHeight = userHeight > 0 ? Int(userHeight) : cellHeight
            
            presentSheet(
                on: self,
                buildView: {
                    let v = EditHeightView()
                    v.setDefaultHeight(defaultHeight)
                    return v
                }) { [weak self] view in
                    guard let self, let v = view as? EditHeightView else { return }
                    let newHeight = v.selectedHeight
                    let u = self.currentUser
                    
                    self.userVM.saveUser(
                        age: u?.age ?? 0,
                        gender: u?.gender ?? "",
                        height: Double(newHeight),
                        weight: u?.weight ?? 0,
                        diseases: u?.diseases as? [Disease]
                    )
                    
                    if self.items.indices.contains(indexPath.row) {
                        self.items[indexPath.row].detail = "\(Int(newHeight))cm"
                    }
                    self.fetchUserInfoAndSetupUI()
                }
        default:
            break
        }
    }
}
