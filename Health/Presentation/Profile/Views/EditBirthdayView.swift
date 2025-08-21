//
//  EditBirthdayView.swift
//  Health
//
//  Created by 하재준 on 8/10/25.
//

import UIKit
import CoreData

class EditBirthdayView: CoreView {
    
    private let titleLabel = UILabel()
    private let pickerView = UIPickerView()
    private var years: [Int] = []
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    override func setupHierarchy() {
        addSubviews(titleLabel, pickerView)
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        backgroundColor = .clear
        
        titleLabel.configureAsTitle("태어난 해")
        self.selectedYear = Calendar.current.component(.year, from: Date())
        
        setupYears()
        setupPicker()
        
        setDefaultSelection()
    }
    
    override func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            pickerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            pickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func clampYear(_ y: Int) -> Int {
        guard let first = years.first, let last = years.last else { return y }
        return min(max(y, first), last)
    }
    
    private func setupYears() {
        let currentYear = Calendar.current.component(.year, from: Date())
        years = Array(1900...currentYear)
    }
    
    private func setupPicker() {
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setDefaultSelection() {
        if let yearIndex = years.firstIndex(of: selectedYear) {
            pickerView.selectRow(yearIndex, inComponent: 0, animated: false)
        }
    }
    
    func setDefaultYear(_ year: Int) {
        selectedYear = clampYear(year)
        setDefaultSelection()
    }
    
    func getSelectedYear() -> Int {
        return selectedYear
    }
    
    func updateYear() {
            let context = CoreDataStack.shared.viewContext
            let request: NSFetchRequest<UserInfoEntity> = UserInfoEntity.fetchRequest()
            
            do {
                if let userInfo = try context.fetch(request).first, userInfo.age > 0 {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    let calculatedYear = currentYear - Int(userInfo.age)
                    setDefaultYear(calculatedYear)
                }
            } catch {
                print("Core Data fetch 실패: \(error)")
            }
        }
    
    // MARK: - updateYear 사용 예제
    /*
    let birthdayView = EditBirthdayView()
    birthdayView.updateYear()
    print("생년: \(birthdayView.getSelectedYear())")
    */
    
    
}

extension EditBirthdayView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return years.count
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return bounds.width
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(years[row])년"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedYear = years[row]
    }
}
