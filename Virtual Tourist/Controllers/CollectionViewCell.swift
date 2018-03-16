//
//  CollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Thomas Milgrew on 2/27/18.
//  Copyright © 2018 Thomas Milgrew. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
//    override var isSelected: Bool{
//        didSet{
//            if self.isSelected{
//                self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
//                self.contentView.backgroundColor = UIColor.gray
//                self.imageView.isOpaque = true
//            } else {
//                self.transform = CGAffineTransform.identity
//                self.contentView.backgroundColor = UIColor.red
//                self.imageView.isHidden = true
//            }
//        }
//    }
}
