//
//  EditWeightView.swift
//  Health
//
//  Created by 하재준 on 8/10/25.
//

import UIKit

final class EditWeightView: CoreView {
    
    private let pickerView: UIPickerView = {
        let v = UIPickerView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let weights: [Int] = Array(30...200)
    var selectedWeight: Int = 70
    
    override func setupHierarchy() {
        addSubview(pickerView)
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        backgroundColor = .clear
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
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
    
    private func setInitialSelection() {
        if let idx = weights.firstIndex(of: selectedWeight) {
            pickerView.selectRow(idx, inComponent: 0, animated: false)
        }
    }
    
    func getSelectedWeight() -> Int {
        return selectedWeight
    }
    
    func setInitialWeight(_ weight: Int) {
        selectedWeight = min(max(weight, weights.first ?? 30), weights.last ?? 200)
        setInitialSelection()
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
