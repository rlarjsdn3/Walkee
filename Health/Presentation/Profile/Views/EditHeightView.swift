//
//  EditHeightView.swift
//  Health
//
//  Created by 하재준 on 8/10/25.
//

import UIKit

final class EditHeightView: CoreView {
    
    private let titleLabel = UILabel()
    
    private let pickerView = UIPickerView()
    
    private let heights: [Int] = Array(120...220)
    var selectedHeight: Int = 170
    
    override func setupHierarchy() {
        addSubviews(titleLabel, pickerView)
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        backgroundColor = .clear
        
        titleLabel.configureAsTitle("키")
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
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
    
    private func setDefaultSelection() {
        if let idx = heights.firstIndex(of: selectedHeight) {
            pickerView.selectRow(idx, inComponent: 0, animated: false)
        }
    }
    
    func getSelectedHeight() -> Int {
        selectedHeight
    }
    
    func setDefaultHeight(_ height: Int) {
        selectedHeight = min(max(height, heights.first ?? 120), heights.last ?? 220)
        setDefaultSelection()
    }
}

extension EditHeightView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return heights.count
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        let total = max(bounds.width, 1)
        return total
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(heights[row]) cm"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedHeight = heights[row]
    }
}
