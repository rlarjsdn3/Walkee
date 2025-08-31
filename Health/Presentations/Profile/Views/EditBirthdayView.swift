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
        
        let pickerHeight: CGFloat = traitCollection.userInterfaceIdiom == .pad ? 300 : 216
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: -48),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            pickerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            pickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: pickerHeight),
            pickerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    /// 클램핑(clamping)을 통해 주어진 연도를 허용된 범위(`years`) 안으로 제한합니다.
    ///
    /// `years` 배열의 첫 번째 값과 마지막 값을 기준으로 연도를 제한합니다.
    /// - 만약 주어진 값이 범위보다 작으면 최소값으로, 크면 최대값으로 맞춰집니다.
    /// - 배열이 비어있다면 원래 값(`y`)을 그대로 반환합니다.
    ///
    /// - Parameter y: 제한하고자 하는 연도 값.
    /// - Returns: `years` 배열의 최소~최대 범위 내로 제한된 연도 값.
    private func clampYear(_ y: Int) -> Int {
        guard let first = years.first, let last = years.last else { return y }
        return min(max(y, first), last)
    }
    
    private func setupYears() {
        let currentYear = Calendar.current.component(.year, from: Date())
        years = Array(1900...(currentYear - 1))
    }
    
    private func setupPicker() {
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    /// `pickerView`의 기본 선택 상태를 설정합니다.
    ///
    /// 현재 선택된 연도(`selectedYear`)가 `years` 배열에 존재한다면,
    /// 해당 인덱스를 찾아 `pickerView`의 첫 번째 컴포넌트(연도 선택)에 반영합니다.
    /// - 배열에 값이 존재하지 않으면 아무 동작도 하지 않습니다.
    ///
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
