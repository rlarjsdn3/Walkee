//
//  EditHeightView.swift
//  Health
//
//  Created by 하재준 on 8/10/25.
//

import UIKit

final class EditHeightView: CoreView {

    private let pickerView: UIPickerView = {
        let v = UIPickerView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let heights: [Int] = Array(120...220)
    var selectedHeight: Int = 170

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
        if let idx = heights.firstIndex(of: selectedHeight) {
            pickerView.selectRow(idx, inComponent: 0, animated: false)
        }
    }

    func getSelectedHeight() -> Int {
        selectedHeight
    }

    func setInitialHeight(_ height: Int) {
        selectedHeight = min(max(height, heights.first ?? 120), heights.last ?? 220)
        setInitialSelection()
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
