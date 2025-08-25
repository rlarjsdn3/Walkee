//
//  EditWeightView.swift
//  Health
//
//  Created by 하재준 on 8/10/25.
//

import UIKit

final class EditWeightView: CoreView {
    
    private let titleLabel = UILabel()
    
    private let pickerView = UIPickerView()
    
    private let weights: [Int] = Array(30...200)
    var selectedWeight: Int = 70
    
    override func setupHierarchy() {
        addSubviews(titleLabel, pickerView)
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        backgroundColor = .clear
        
        titleLabel.configureAsTitle("체중")
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        setDefaultSelection()
    }
    
    override func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            pickerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            pickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
    }
    
    private func setDefaultSelection() {
        if let idx = weights.firstIndex(of: selectedWeight) {
            pickerView.selectRow(idx, inComponent: 0, animated: false)
        }
    }
    
    func getSelectedWeight() -> Int {
        return selectedWeight
    }
    
    func setDefaultWeight(_ weight: Int) {
        selectedWeight = min(max(weight, weights.first ?? 30), weights.last ?? 200)
        setDefaultSelection()
    }
}

extension EditWeightView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return weights.count
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return max(bounds.width, 1)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(weights[row])kg"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedWeight = weights[row]
    }
}
