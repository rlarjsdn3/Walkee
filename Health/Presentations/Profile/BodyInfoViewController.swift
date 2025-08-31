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

class BodyInfoViewController: HealthNavigationController, Alertable {

    @IBOutlet weak var tableView: UITableView!

    @Injected private var userService: (any CoreDataUserService)

    private var currentUser: UserInfoEntity?

    private var profileSheetHeightConstraint: NSLayoutConstraint?
    private weak var profileSheet: TSAlertController?


    private var items: [BodyInfoItem] = [
        .init(iconName: "figure.stand.dress.line.vertical.figure", title: "성별", detail: "-"),
        .init(iconName: "birthday.cake", title: "태어난 해", detail: "-"),
        .init(iconName: "scalemass", title: "체중", detail: "-"),
        .init(iconName: "ruler", title: "키", detail: "-"),
        .init(iconName: "cross", title: "지병", detail: "-")
    ]

    override func setupAttribute() {
        super.setupAttribute()

        healthNavigationBar.title = "신체 정보"

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

        let padLand = isPadLandscapeNow()
        let baseH: CGFloat = 0.33
        let baseW: CGFloat = 0.9
        let landH: CGFloat = 0.25
        let landW: CGFloat = 0.6
        let h = padLand ? landH : baseH
        let w = padLand ? landW : baseW

        alert.viewConfiguration.size.width  = .proportional(minimumRatio: w, maximumRatio: w)
        alert.viewConfiguration.size.height = .proportional(minimumRatio: h, maximumRatio: h)

        profileSheetHeightConstraint?.constant = view.bounds.height * h

        alert.view.layoutIfNeeded()
    }

    private func isPadLandscapeNow() -> Bool {
        let isPad = traitCollection.userInterfaceIdiom == .pad
        let iface = view.window?.windowScene?.interfaceOrientation
        return isPad && (iface?.isLandscape == true)
    }

    private func updateDiseaseText(with diseases: [Disease]) {
        guard let diseaseIndex = items.firstIndex(where: { $0.title == "지병" }) else { return }

        if diseases.isEmpty {
            items[diseaseIndex].detail = "-"
        } else if diseases.first == Disease.none {
            items[diseaseIndex].detail = "없음"
        } else if diseases.count >= 1 {
            items[diseaseIndex].detail = "\(diseases.count)개"
        }
    }
    
    /// 사용자 정보를 가져와 화면(UI)에 반영합니다.
    ///
    /// - `userService.fetchUserInfo()`를 통해 현재 사용자 정보를 불러옵니다.
    /// - 불러오기 전에는 모든 세부 항목(성별, 출생년도, 몸무게, 키, 지병)을 `"-"`로 초기화합니다.
    /// - 가져온 값이 유효할 경우, 각 항목을 실제 데이터로 채웁니다:
    /// - 사용자 정보 로드가 실패하면 오류를 로그로 출력합니다.
    @MainActor
    private func fetchUserInfoAndSetupUI() {
        setDetail("-", at: 0) // 성별
        setDetail("-", at: 1) // 출생년도
        setDetail("-", at: 2) // 몸무게
        setDetail("-", at: 3) // 키
        setDetail("-", at: 4) // 지병

        do {
            let u = try userService.fetchUserInfo()
            currentUser = u

            // 성별
            let genderText = (u.gender ?? "").isEmpty ? "-" : (u.gender ?? "-")
            setDetail(genderText, at: 0)

            // 태어난 해
            let age = Int(u.age)
            if age > 0 {
                let year = Calendar.current.component(.year, from: Date()) - age
                setDetail("\(year)년", at: 1)
            }

            // 체중
            if u.weight > 0 {
                setDetail("\(Int(u.weight))kg", at: 2)
            }
            
            // 키
            if u.height > 0 {
                setDetail("\(Int(u.height))cm", at: 3)
            }
            
            // 지병
            if let diseases = u.diseases, !diseases.isEmpty {
                updateDiseaseText(with: diseases)
            }

        } catch {
            print("fetchUserInfo 실패: \(error)")
        }

        tableView.reloadData()
    }

    private func setDetail(_ text: String, at index: Int) {
        guard items.indices.contains(index) else { return }
        items[index].detail = text
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

                    Task {
                        do {
                            try await self.userService.updateUserInfo(
                                age: Int(u?.age ?? 0),
                                gender: selected.rawValue,
                                height: u?.height ?? 0,
                                weight: u?.weight ?? 0,
                                diseases: u?.diseases
                            )
                            print("성별 저장 성공")
                            await MainActor.run {
                                self.fetchUserInfoAndSetupUI()
                            }
                        } catch {
                            print("성별 저장 실패: \(error)")
                        }
                    }
                }
            )
        case "태어난 해":
            let currentYear = Date().year
            let defaultYear: Int = {
                let digits = items[indexPath.row].detail.filter(\.isNumber)
                if let cellYear = Int(digits), cellYear > 0 {
                    return cellYear
                }

                let context = CoreDataStack.shared.viewContext
                let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
                do {
                    if let userInfo = try context.fetch(request).first, userInfo.age > 0 {
                        return currentYear - Int(userInfo.age)
                    }
                } catch {
                    print("Core Data fetch 실패: \(error)")
                }

                return currentYear
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

                    Task {
                        do {
                            try await self.userService.updateUserInfo(
                                age: age,
                                gender: u?.gender,
                                height: u?.height,
                                weight: u?.weight,
                                diseases: u?.diseases
                            )
                            print("나이 저장 성공")
                            if let user = self.currentUser {
                                print(user.age)
                            }
                            await MainActor.run {
                                self.fetchUserInfoAndSetupUI()
                            }
                        } catch {
                            print("나이 저장 실패: \(error)")
                        }
                    }

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

                    Task {
                        do {
                            try await self.userService.updateUserInfo(
                                age: Int(u?.age ?? 0),
                                gender: u?.gender,
                                height: u?.height,
                                weight: Double(newWeight),
                                diseases: u?.diseases
                            )
                            print("체중 저장 성공")
                            await MainActor.run {
                                self.fetchUserInfoAndSetupUI()
                            }
                        } catch {
                            print("체중 저장 실패: \(error)")
                        }
                    }
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

                    Task {
                        do {
                            try await self.userService.updateUserInfo(
                                age: Int(u?.age ?? 0),
                                gender: u?.gender,
                                height: Double(newHeight),
                                weight: u?.weight,
                                diseases: u?.diseases
                            )
                            print("키 저장 성공")
                            await MainActor.run {
                                self.fetchUserInfoAndSetupUI()
                            }
                        } catch {
                            print("키 저장 실패: \(error)")
                        }
                    }
                }
            )
        case "지병":
            showActionSheetForProfile(
                buildView: {
                    let v = EditDiseaseView()
                    if let currentDisease = self.currentUser?.diseases as? [Disease] {
                        v.setSelectedDiseases(currentDisease)
                    }
                    return v
                },
                height: 600,
                width: 800,
                iPadLandscapeHeight: 700,
                iPadLandscapeWidth: 700,
                onConfirm: { [weak self] view in
                    guard let self, let v = view as? EditDiseaseView else { return }

                    let selectedDiseases = v.getSelectedDiseases()
                    let u = self.currentUser

                    Task {
                        do {
                            try await self.userService.updateUserInfo(
                                age: Int(u?.age ?? 0),
                                gender: u?.gender,
                                height: u?.height,
                                weight: u?.weight,
                                diseases: selectedDiseases
                            )
                            print("지병 저장 성공")
                            await MainActor.run {
                                self.fetchUserInfoAndSetupUI()
                            }
                        } catch {
                            print("지병 저장 실패: \(error)")
                        }
                    }
                    self.updateDiseaseText(with: selectedDiseases)
                }
            )
        default:
            break
        }
    }
}
