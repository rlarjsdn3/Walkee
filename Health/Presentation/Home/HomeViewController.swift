//
//  HomeViewController.swift
//  Health
//
//  Created by 김건우 on 7/28/25.
//

import UIKit

import TSAlertController

class ViewController: UIViewController, Alertable {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tapped(_ sender: Any) {
        showDestructiveAlert(
            "Hello, World!",
            message: "Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!Hello, World!",
        ) { _ in
            print("Tapped OK")
        } onCancelAction: { _ in
            print("Tapped Cancel")
        }
    }
}
