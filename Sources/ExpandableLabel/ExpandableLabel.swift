// The Swift Programming Language
// https://docs.swift.org/swift-book

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
        /// 未展开的最大行数
        public var unexpandedMaxLines: UInt = 3
        /// 展开后的最大行数，默认为0，无限制
        public var expandedMaxLines: UInt = 0
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
    
    private var width: Double {
        configuration.width
    }
    
    private var lineHeight: Double {
        configuration.font.lineHeight
    }
    
    public func update(configuration: Configuration) {
        self.configuration = configuration
    }
    
    private func didUpdateConfiguration() {
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
                // For 22.4 lineHeight, we want button 22.4, image 16
                // The padding is 1/7 lineHeight
                let insetPadding = lineHeight / 7
                expandButton.imageView?.snp.remakeConstraints { make in
                    make.center.equalToSuperview()
                    make.size.equalToSuperview().inset(insetPadding)
                }
                
                // For 22.4 lineHeight, we want button 22.4, image 16
                // The outsetPadding is 11/28 lineHeight
                let outsetPadding = lineHeight * 11 / 28
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
    
    public init(configuration: Configuration) {
        self.configuration = configuration
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
    }
    
    override public var intrinsicContentSize: CGSize {
        CGSize(
            width: width,
            height: sizeThatFits(CGSize(width: width, height: .infinity)).height
        )
    }
}
