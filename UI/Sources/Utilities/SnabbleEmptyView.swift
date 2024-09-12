//
//  ReceiptsEmptyView.swift
//
//
//  Created by Uwe Tilemann on 10.04.24.
//

import SwiftUI
import SnabbleAssetProviding

public struct SnabbleEmptyView: View {
    public let title: String
    public let subtitle: String?
    public let image: Image
    public let imageWidth: CGFloat
    
	public init(title: String, subtitle: String? = nil, image: Image, imageWidth: CGFloat = 72) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.imageWidth = imageWidth
    }

    public var body: some View {
        VStack(spacing: 32) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: imageWidth)
                .foregroundColor(.projectPrimary())
            
            Text(title)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding([.leading, .trailing], 48)
            if let subtitle {
                Text(subtitle)
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding([.leading, .trailing], 48)
            }
        }
        .padding()
    }
}

public class ReceiptsEmptyViewController: UIHostingController<SnabbleEmptyView> {
    public init() {
        super.init(rootView: SnabbleEmptyView(
            title: Asset.localizedString(forKey: "Snabble.Receipts.noReceipts"),
            image: SwiftUI.Image.image(named: "scroll", systemName: "scroll")))
    }
        
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class PaymentEmptyViewController: UIHostingController<SnabbleEmptyView> {
    public init() {
        super.init(rootView: SnabbleEmptyView(
            title: Asset.localizedString(forKey: "Snabble.Payment.EmptyState.message"),
            image: SwiftUI.Image.image(named: "creditcard", systemName: "creditcard"))
        )
    }
    
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
