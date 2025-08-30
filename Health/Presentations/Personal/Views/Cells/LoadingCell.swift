//
//  LoadingCell.swift
//  Health
//
//  Created by juks86 on 8/20/25.
//

import UIKit

class LoadingCell: CoreCollectionViewCell {

    @IBOutlet weak var loadingView: WalkingLoadingView!

    override func awakeFromNib() {
          super.awakeFromNib()
      }

      func configure(with state: WalkingLoadingView.State) {
          loadingView.setState(state)
      }

      override func prepareForReuse() {
          super.prepareForReuse()
          loadingView.setState(.loading)
      }
  }
