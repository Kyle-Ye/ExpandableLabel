//
//  ExpandableLabel.swift
//
//
//  Created by Kyle on 2024/6/7.
//

import os.log
import SnapKit
import UIKit
import YYText

public final class ExpandableLabel: YYLabel {
    public struct Configuration {
        public var width: Double
        public var font: UIFont
        public var textColor: UIColor
        public var buttonColor: UIColor?
        /// Max lines for unexpanded state
        public var unexpandedMaxLines: UInt
        /// Max lines for expanded state
        public var expandedMaxLines: UInt
        public var expandableScope: ExpandableScope
        
        public init(
            width: Double,
            font: UIFont,
            textColor: UIColor,
            buttonColor: UIColor? = nil,
            unexpandedMaxLines: UInt = 3,
            expandedMaxLines: UInt = 0,
            expandableScope: ExpandableScope = .button
        ) {
            self.width = width
            self.font = font
            self.textColor = textColor
            self.buttonColor = buttonColor
            self.unexpandedMaxLines = unexpandedMaxLines
            self.expandedMaxLines = expandedMaxLines
            self.expandableScope = expandableScope
        }
    }
    
    public enum ExpandableScope: Int, CaseIterable {
        case button
        case text
    }
    
    public protocol Delegate: AnyObject {
        func expandableLabel(_ label: ExpandableLabel, didChangeExpandState isExpanded: Bool)
    }
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "",
        category: "ExpandableLabel"
    )
    
    private var configuration: Configuration {
        didSet {
            didUpdateConfiguration()
        }
    }
    
    private weak var delegate: Delegate?
    
    private var width: Double {
        configuration.width
    }
    
    private var lineHeight: Double {
        configuration.font.lineHeight
    }
    
    public func update(configuration: Configuration? = nil, delegate: Delegate? = nil) {
        if let configuration {
            self.configuration = configuration
        }
        if let delegate {
            self.delegate = delegate
        }
    }
    
    private lazy var tapGesture = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(toggleExpand))
        return gesture
    }()
    
    private func didUpdateConfiguration() {
        expandButton.removeTarget(self, action: #selector(toggleExpand), for: .touchUpInside)
        removeGestureRecognizer(tapGesture)
        switch configuration.expandableScope {
            case .button:
                expandButton.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)
            case .text:
                addGestureRecognizer(tapGesture)
        }
        font = configuration.font
        tintColor = configuration.textColor
        expandButton.tintColor = configuration.buttonColor ?? configuration.textColor
        numberOfLines = isExpanded ? configuration.expandedMaxLines : configuration.unexpandedMaxLines
        
        // Protected YYText Crash
        if bounds.size != .zero {
            updateExclusionPath()
        }
    }
    
    override public var text: String? {
        get {
            super.text
        }
        set {
            if let newValue = newValue {
                attributedText = NSAttributedString(
                    string: newValue,
                    attributes: [
                        .font: configuration.font,
                        .foregroundColor: configuration.textColor,
                    ]
                )
            } else {
                attributedText = nil
            }
            sizeToFit()
            if canExpand {
                addSubview(expandButton)
                expandButton.snp.remakeConstraints { make in
                    make.size.equalTo(lineHeight)
                    make.trailing.bottom.equalToSuperview()
                }
                let insetPadding = lineHeight / 8
                expandButton.imageView?.snp.remakeConstraints { make in
                    make.center.equalToSuperview()
                    make.size.equalToSuperview().inset(insetPadding)
                }
                
                let outsetPadding = lineHeight / 8
                expandButton.tapAreaInsets = UIEdgeInsets(top: outsetPadding, left: outsetPadding, bottom: outsetPadding, right: outsetPadding)
            } else {
                expandButton.removeFromSuperview()
            }
        }
    }
    
    public var canExpand: Bool {
        // Use a new container with unlimited line to calculate the original content height
        let container = YYTextContainer()
        container.size = CGSize(width: width, height: YYTextContainerMaxSize.height)
        guard let rawLayouts = YYTextLayout.layout(with: [container], text: attributedText ?? NSAttributedString(string: "")),
              let rawLayout = rawLayouts.first
        else {
            Self.logger.error("canExpand: rawLayout invalid")
            return false
        }
        return rawLayout.rowCount > configuration.unexpandedMaxLines
    }

    public var isExpanded = false {
        didSet {
            if isExpanded {
                numberOfLines = configuration.expandedMaxLines
                expandButton.setImage(UIImage(systemName: "arrow.up"), for: [])
            } else {
                numberOfLines = configuration.unexpandedMaxLines
                expandButton.setImage(UIImage(systemName: "arrow.down"), for: [])
            }
        }
    }
    
    private lazy var expandButton = {
        let button = EnlargedTapAreaButton(frame: .zero)
        button.setImage(UIImage(systemName: "arrow.down"), for: [])
        button.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)
        button.tintColor = configuration.buttonColor ?? configuration.textColor
        return button
    }()
    
    private var expandButtonPath: UIBezierPath {
        UIBezierPath(
            rect: CGRect(
                x: bounds.maxX - lineHeight,
                y: bounds.maxY - lineHeight,
                width: lineHeight,
                height: lineHeight
            )
        )
    }
    
    private func updateExclusionPath() {
        if canExpand {
            exclusionPaths = [expandButtonPath]
        } else {
            exclusionPaths = []
        }
    }
    
    public init(configuration: Configuration, delegate: Delegate? = nil) {
        self.configuration = configuration
        self.delegate = delegate
        super.init(frame: .zero)
        didUpdateConfiguration()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        guard sizeThatFits(bounds.size).width + expandButtonPath.bounds.width >= width else {
            return
        }
        updateExclusionPath()
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func toggleExpand() {
        Self.logger.info("ExpandableLabel button click")
        isExpanded.toggle()
        layoutIfNeeded()
        delegate?.expandableLabel(self, didChangeExpandState: isExpanded)
    }
    
    override public var intrinsicContentSize: CGSize {
        CGSize(
            width: width,
            height: sizeThatFits(CGSize(width: width, height: .infinity)).height
        )
    }
}

#if DEBUG
import SwiftUI

@available(iOS 16, *)
#Preview {
    ExpandableLabelLivePreview()
}
#endif
