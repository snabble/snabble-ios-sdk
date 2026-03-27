//
//  CheckoutHeaderView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 06.02.23.
//

import Foundation
import SwiftUI
import SnabbleAssetProviding

protocol CheckoutHeaderViewModel {
    var statusViewModel: CheckoutStepStatusViewModel { get }
    var text: String { get }
}

struct CheckoutHeaderView: View {
    var model: CheckoutHeaderViewModel

    init(model: CheckoutHeaderViewModel) {
        self.model = model
    }
    var body: some View {
        VStack(spacing: 20) {
            Text(model.text)
                .font(.headline)
            CheckoutStepStatusView(model: model.statusViewModel, large: true)
        }
    }
}

extension CheckoutStepStatus: CheckoutHeaderViewModel {
    var text: String {
        switch self {
        case .loading:
            return Asset.localizedString(forKey: "Snabble.Payment.waiting")
        case .failure, .aborted:
            return Asset.localizedString(forKey: "Snabble.Payment.rejected")
        case .success:
            return Asset.localizedString(forKey: "Snabble.Payment.success")
        }
    }

    var statusViewModel: CheckoutStepStatusViewModel {
        self
    }
}

#if DEBUG
import SwiftUI

@available(iOS 13, *)
public struct CheckoutHeaderView_Previews: PreviewProvider {
    public static var previews: some View {
        Group {
            CheckoutHeaderView(model: CheckoutStepStatus.failure)
                .previewLayout(.fixed(width: 100, height: 100))
                    .preferredColorScheme(.dark)
            CheckoutHeaderView(model: CheckoutStepStatus.failure)
                .previewLayout(.fixed(width: 300, height: 300))
                    .preferredColorScheme(.light)
        }
    }
}
#endif
