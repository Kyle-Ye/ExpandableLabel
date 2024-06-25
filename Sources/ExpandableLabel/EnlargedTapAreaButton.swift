//
//  EnlargedTapAreaButton.swift
//
//
//  Created by Kyle on 2024/6/24.
//

import UIKit

open class EnlargedTapAreaButton: UIButton {
    // Define the extra padding for the tap area
    open var tapAreaInsets: UIEdgeInsets = .zero
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let largerArea = bounds.inset(by: tapAreaInsets.inverted())
        return largerArea.contains(point)
    }
}

extension UIEdgeInsets {
    func inverted() -> UIEdgeInsets {
        UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
    }
}
