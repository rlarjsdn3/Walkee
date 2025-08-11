//
//  EditViewController.swift
//  Health
//
//  Created by 하재준 on 8/8/25.
//

import UIKit

class EditViewController: CoreGradientViewController {

    @IBAction func confirm(_ sender: Any) {
        dismiss(animated: true)
    }
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    override func setupAttribute() {
        super.setupAttribute()
        
        applySolidBackground(.midnightBlackBackground)
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
    
}
