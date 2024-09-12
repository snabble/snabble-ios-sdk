//
//  TextViewController.swift
//  Snabble
//
//  Created by Uwe Tilemann on 08.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import SwiftUI
import UIKit
import SnabbleAssetProviding

extension String {
    public var containsHTML: Bool {
        var flag = false

        if let start = self.range(of: "<a"),
           let href = self.range(of: "href=\""),
           let end = range(of: "</a>"),
           start.lowerBound < end.upperBound {
            flag = href.overlaps(start.lowerBound..<end.upperBound)
        }
        return flag
    }

    public var attributedStringFromHTML: NSAttributedString? {

        guard let data = self.data(using: .utf16, allowLossyConversion: true),
              let attributedString = try? NSMutableAttributedString(data: data,
                                                                    options: [.documentType: NSAttributedString.DocumentType.html],
                                                                    documentAttributes: nil) else {
            return nil
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .subheadline),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label
        ]
        attributedString.addAttributes(attributes, range: NSRange(location: 0, length: attributedString.length))

        var links: [NSRange] = []

        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { (attrs, range, _) in
            if attrs[.link] != nil {
                links.append(range)
            }
        }

        for range in links {
            attributedString.addAttributes([.foregroundColor: UIColor.projectPrimary(),
                                            .underlineStyle: 0], range: range)

        }

        return attributedString
    }
}

struct AttributedText: UIViewRepresentable {
    typealias UIViewType = UITextView

    let htmlString: String
    @Binding var openURL: URL?

    @State private var attributedText: NSAttributedString?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIViewType {
        let view = ContentTextView()
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.contentInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        guard let attributedText = attributedText else {
            generateAttributedText()
            return
        }
        uiView.attributedText = attributedText
    }

    private func generateAttributedText() {
        guard attributedText == nil else { return }
        // create attributedText on main thread since HTML formatter will crash SwiftUI
        DispatchQueue.main.async {
            self.attributedText = self.htmlString.attributedStringFromHTML
        }
    }

    /// ContentTextView
    /// subclass of UITextView returning contentSize as intrinsicContentSize
    private class ContentTextView: UITextView {
        override var canBecomeFirstResponder: Bool { false }

        override var intrinsicContentSize: CGSize {
            frame.height > 0 ? contentSize : super.intrinsicContentSize
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var control: AttributedText

        init(_ control: AttributedText) {
            self.control = control
        }
        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            if case .link(let url) = textItem.content {
                self.control.openURL = url
            }
            return nil
        }
    }

}

struct AttributedText_Previews: PreviewProvider {
    static let OnboardingCaption0 = "Es gelten die <a href=\"teo://terms\">Nutzungsbedingungen</a>. Bitte beachte unsere Hinweise zum <a href=\"teo://privacy\">Datenschutz</a>."

    static var previews: some View {
        AttributedText(htmlString: OnboardingCaption0, openURL: .constant(URL(fileURLWithPath: "/")))
    }
}
