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

class BodyInfoViewController: CoreGradientViewController, Alertable {
    
    @IBOutlet weak var tableView: UITableView!
    
    @Injected private var userVM: UserInfoViewModel
    
    private var currentUser: UserInfoEntity?
    
    private var profileSheetHeightConstraint: NSLayoutConstraint?
    private weak var profileSheet: TSAlertController?
    
    
    private var items: [BodyInfoItem] = [
        .init(iconName: "figure.stand.dress.line.vertical.figure", title: "성별", detail: "-"),
        .init(iconName: "birthday.cake", title: "태어난 해", detail: "-"),
        .init(iconName: "scalemass", title: "체중", detail: "-"),
        .init(iconName: "ruler", title: "키", detail: "-"),
        .init(iconName: "cross", title: "질병", detail: "-")
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard let alert = profileSheet else { return }

        // 원하는 비율 재계산
        let padLand = isPadLandscapeNow()
        let baseH: CGFloat = 0.33
        let baseW: CGFloat = 0.9
        let landH: CGFloat = 0.25
        let landW: CGFloat = 0.6
        let h = padLand ? landH : baseH
        let w = padLand ? landW : baseW

        alert.viewConfiguration.size.width  = .proportional(minimumRatio: w, maximumRatio: w)
        alert.viewConfiguration.size.height = .proportional(minimumRatio: h, maximumRatio: h)

        // 컨텐츠 높이 제약 업데이트
        profileSheetHeightConstraint?.constant = view.bounds.height * h

        alert.view.layoutIfNeeded()
    }
    
    private func isPadLandscapeNow() -> Bool {
        let isPad = traitCollection.userInterfaceIdiom == .pad
        let iface = view.window?.windowScene?.interfaceOrientation
        return isPad && (iface?.isLandscape == true)
    }
    
    private func updateDiseaseText(with diseases: [Disease]) {
        guard let diseaseIndex = items.firstIndex(where: { $0.title == "질병" }) else { return }
        
        if diseases.isEmpty {
            items[diseaseIndex].detail = "-"
        } else if diseases.first == Disease.none {
            items[diseaseIndex].detail = "없음"
        } else if diseases.count > 1 {
            items[diseaseIndex].detail = "\(diseases.count)개"
        }
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
                    items[1].detail = "\(year)년"
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
            
            if items.indices.contains(4) {
                if let diseases = u.diseases {
                    updateDiseaseText(with: diseases)
                } else {
                    items[4].detail = "-"
                }
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
            showActionSheetForProfile(
                buildView: {
                    let v = EditGenderView()
                    v.setDefaultGender(currentGender)
                    return v
                },
                onConfirm: { [weak self] view in
                    guard let self,
                          let v = view as? EditGenderView,
                          let selected = v.selectedGender else { return }
                    
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
            )
        case "태어난 해":
            let currentYear = Calendar.current.component(.year, from: Date())
            
            let defaultYear: Int = {
                let context = CoreDataStack.shared.viewContext
                let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
                
                do {
                    if let userInfo = try context.fetch(request).first, userInfo.age > 0 {
                        let calculatedYear = currentYear - Int(userInfo.age)
                        return calculatedYear
                    }
                } catch {
                    print("Core Data fetch 실패: \(error)")
                }
                
                // Core Data에서 가져오지 못한 경우, 기존 cell의 값을 사용하거나 현재년도 사용
                let digits = items[indexPath.row].detail.filter(\.isNumber)
                let cellYear = Int(digits)
                return (cellYear ?? 0) > 0 ? cellYear! : currentYear
            }()
            
            showActionSheetForProfile(
                buildView: {
                    let v = EditBirthdayView()
                    v.setDefaultYear(defaultYear)
                    return v
                },
                onConfirm: { [weak self] view in
                    guard let self, let v = view as? EditBirthdayView else { return }
                    let selectedYear = v.getSelectedYear()
                    let age = currentYear - selectedYear
                    let u = self.currentUser
                    self.userVM.saveUser(
                        age: Int16(age),
                        gender: u?.gender ?? "",
                        height: u?.height ?? 0,
                        weight: u?.weight ?? 0,
                        diseases: u?.diseases as? [Disease]
                    )
                    
                    if self.items.indices.contains(indexPath.row) {
                        // Core Data에서 나이를 다시 가져와서 태어난 년도 계산하여 detail에 설정
                        let context = CoreDataStack.shared.viewContext
                        let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
                        
                        do {
                            if let userInfo = try context.fetch(request).first, userInfo.age > 0 {
                                let birthYear = currentYear - Int(userInfo.age)
                                self.items[indexPath.row].detail = "\(birthYear)년"
                            } else {
                                self.items[indexPath.row].detail = "\(selectedYear)년"
                            }
                        } catch {
                            print("Core Data fetch 실패: \(error)")
                            self.items[indexPath.row].detail = "\(selectedYear)년"
                        }
                    }
                    self.fetchUserInfoAndSetupUI()
                }
            )
          
        case "체중":
            let userWeight = currentUser?.weight ?? 0
            let cellWeight: Int = {
                let t = items[indexPath.row].detail
                let digits = t.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                return Int(digits) ?? 70
            }()
            let defaultWeight = userWeight > 0 ? Int(userWeight) : cellWeight
            
            showActionSheetForProfile(
                buildView: {
                    let v = EditWeightView()
                    v.setDefaultWeight(defaultWeight)
                    return v
                }, onConfirm: { [weak self] view in
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
            )
          
        case "키":
            let userHeight = currentUser?.height ?? 0
            let cellHeight: Int = {
                let t = items[indexPath.row].detail
                let digits = t.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                return Int(digits) ?? 170
            }()
            let defaultHeight = userHeight > 0 ? Int(userHeight) : cellHeight
           
            showActionSheetForProfile(
                buildView: {
                    let v = EditHeightView()
                    v.setDefaultHeight(defaultHeight)
                    return v
                }, onConfirm: { [weak self] view in
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
            )
        case "질병":
            showActionSheetForProfile(
                buildView: {
                let v = EditDiseaseView()
                    if let currentDisease = self.currentUser?.diseases as? [Disease] {
                        v.setSelectedDiseases(currentDisease)
                    }
                    return v
                },
                heightRatio: 0.6,
                widthRatio: 0.9,
                iPadLandscapeHeightRatio: 0.45,
                iPadLandscapeWidthRatio: 0.8,
                onConfirm: { [weak self] view in
                guard let self, let v = view as? EditDiseaseView else { return }
                    
                    let selectedDiseases = v.getSelectedDiseases()
                    let u = self.currentUser
                    
                    self.userVM.saveUser(
                        age: u?.age ?? 0,
                        gender: u?.gender ?? "",
                        height: u?.height ?? 0,
                        weight: u?.weight ?? 0,
                        diseases: selectedDiseases
                    )
                    
                    self.updateDiseaseText(with: selectedDiseases)
                    self.fetchUserInfoAndSetupUI()
            }
            )
        default:
            break
        }
    }
}
