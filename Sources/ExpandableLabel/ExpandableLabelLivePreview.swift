//
//  ExpandableLabelLivePreview.swift
//  
//
//  Created by Kyle on 2024/6/25.
//

#if DEBUG
import SwiftUI

@available(iOS 16.0, *)
struct ExpandableLabelUIViewPreviewView: UIViewRepresentable {
    typealias UIViewType = ExpandableLabel
    
    var model: ExpandableLabelLivePreview.Model
     
    func makeUIView(context _: Context) -> UIViewType {
        let label = ExpandableLabel(configuration: model.config)
        label.text = model.text
        return label
    }
    
    func updateUIView(_ uiView: UIViewType, context _: Context) {
        uiView.update(configuration: model.config)
        uiView.text = model.text
    }
    
    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: ExpandableLabel, context: Context) -> CGSize? {
        uiView.intrinsicContentSize
    }
}

extension ExpandableLabel.ExpandableScope: CustomStringConvertible {
    public var description: String {
        switch self {
            case .button: "Button"
            case .text: "Text"
        }
    }
}

@available(iOS 16.0, *)
struct ExpandableLabelLivePreview: View {
    struct Model {
        var config: ExpandableLabel.Configuration
        var text: String
    }
    
    @State private var model: Model?
    
    @State private var text = ""
    @State private var textColor = Color.primary
    @State private var buttonColor = Color.primary
    @State private var unexpandedMaxLines: UInt = 3
    @State private var expandedMaxLines: UInt = 0
    @State private var expandableScope: ExpandableLabel.ExpandableScope = .button
    
    var body: some View {
        List {
            Section {
                TextEditor(text: $text)
                    .frame(height: 200)
                ColorPicker("Text color", selection: $textColor)
                ColorPicker("Button color", selection: $buttonColor)
                Stepper("Unexpanded max lines: \(unexpandedMaxLines)", value: $unexpandedMaxLines, in: 1 ... 10)
                Stepper("Expanded max lines: \(expandedMaxLines)", value: $expandedMaxLines, in: 0 ... 10)
                Picker("Expandable scope ", selection: $expandableScope) {
                    ForEach(ExpandableLabel.ExpandableScope.allCases, id: \.rawValue) {
                        Text($0.description).tag($0)
                    }
                }
                Button("Update") {
                    model = Model(
                        config: .init(
                            width: UIScreen.main.bounds.width - 64,
                            font: .systemFont(ofSize: 16),
                            textColor: UIColor(textColor),
                            buttonColor: UIColor(buttonColor),
                            unexpandedMaxLines: unexpandedMaxLines,
                            expandedMaxLines: expandedMaxLines,
                            expandableScope: expandableScope
                        ),
                        text: text
                    )
                }
            }
            Section {
                if let model {
                    ExpandableLabelUIViewPreviewView(model: model)
                        .border(Color.red, width: 0.5)
                }
            }
        }
    }
}

@available(iOS 16, *)
#Preview {
    ExpandableLabelLivePreview()
}

#endif
