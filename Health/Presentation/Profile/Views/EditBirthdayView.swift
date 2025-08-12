//
//  EditBirthdayView.swift
//  Health
//
//  Created by 하재준 on 8/10/25.
//

import UIKit

class EditBirthdayView: CoreView {
    
    private let pickerView = UIPickerView()
    private var years: [Int] = []
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
        
    override func setupHierarchy() {
        addSubview(pickerView)
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        backgroundColor = .clear
        
        self.selectedYear = Calendar.current.component(.year, from: Date())

        setupYears()
        setupPicker()
        
        setInitialSelection()
    }
    
    override func setupConstraints() {
        NSLayoutConstraint.activate([
            pickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pickerView.topAnchor.constraint(equalTo: topAnchor),
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
    
    private func setInitialSelection() {
        if let yearIndex = years.firstIndex(of: selectedYear) {
            pickerView.selectRow(yearIndex, inComponent: 0, animated: false)
        }
    }
    
    func setInitialYear(_ year: Int) {
        selectedYear = clampYear(year)
        setInitialSelection()
    }
    
    func getSelectedYear() -> Int {
        return selectedYear
    }
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
