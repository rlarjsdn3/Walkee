//
//  EditBirthdayView.swift
//  Health
//
//  Created by 하재준 on 8/10/25.
//

import UIKit

class EditBirthdayView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    
    private let pickerView = UIPickerView()
    
    private var years: [Int] = []
    private var months: [Int] = Array(1...12)
    private var days: [Int] = []
    
    private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    private var selectedDay: Int = Calendar.current.component(.day, from: Date())
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupYears()
        setupDays(for: selectedYear, month: selectedMonth)
        setupPicker()
        setInitialSelection()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupYears()
        setupDays(for: selectedYear, month: selectedMonth)
        setupPicker()
        setInitialSelection()
    }
    
    private func setupYears() {
        let currentYear = Calendar.current.component(.year, from: Date())
        years = Array(1900...currentYear)
    }
    
    private func setupDays(for year: Int, month: Int) {
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        if let date = calendar.date(from: dateComponents),
           let range = calendar.range(of: .day, in: .month, for: date) {
            days = Array(range)
        }
    }
    
    private func setupPicker() {
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(pickerView)
        
        NSLayoutConstraint.activate([
            pickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pickerView.topAnchor.constraint(equalTo: topAnchor),
            pickerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setInitialSelection() {
        if let yearIndex = years.firstIndex(of: selectedYear) {
            pickerView.selectRow(yearIndex, inComponent: 0, animated: false)
        }
        pickerView.selectRow(selectedMonth - 1, inComponent: 1, animated: false)
        pickerView.selectRow(selectedDay - 1, inComponent: 2, animated: false)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return years.count
        case 1: return months.count
        case 2: return days.count
        default: return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return bounds.width / 3
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0: return "\(years[row])년"
        case 1: return "\(months[row])월"
        case 2: return "\(days[row])일"
        default: return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            selectedYear = years[row]
            setupDays(for: selectedYear, month: selectedMonth)
            pickerView.reloadComponent(2)
        case 1:
            selectedMonth = months[row]
            setupDays(for: selectedYear, month: selectedMonth)
            pickerView.reloadComponent(2)
        case 2:
            selectedDay = days[row]
        default: break
        }
    }
    
    func getSelectedDate() -> Date? {
        let components = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        return Calendar.current.date(from: components)
    }
}

