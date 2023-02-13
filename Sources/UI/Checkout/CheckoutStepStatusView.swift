//
//  CheckoutStepStatusView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 06.02.23.
//
import SwiftUI

protocol CheckoutStepStatusViewModel {
    var circleColor: UIColor? { get }
    var image: SwiftUI.Image? { get }
    var isLoading: Bool { get }
}

struct CheckoutStepStatusView: View {
    var model: CheckoutStepStatusViewModel
    var large: Bool = false

    var body: some View {
        ZStack {
            if let image = model.isLoading ? Image(systemName: "circle.fill") : model.image {
                image
                    .font(large ? .system(size: 152) : .headline)
                    .multiColor(Color(model.isLoading ? .secondarySystemGroupedBackground : model.circleColor ?? .secondarySystemGroupedBackground))
            }
            if model.isLoading {
                ProgressView()
            }
        }
    }
}

extension CheckoutStepStatus: CheckoutStepStatusViewModel {
    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    var circleColor: UIColor? {
        switch self {
        case .loading:
            return .clear
        case .success:
            return .systemGreen
        case .failure:
            return .systemRed
        case .aborted:
            return .systemGray5
        }
    }
    
    var image: Image? {
        switch self {
        case .loading:
            return nil
        case .success:
            return Image(systemName: "checkmark.circle.fill")
        case .failure, .aborted:
            return Image(systemName: "xmark.circle.fill")
       }
    }
}

#if DEBUG
@available(iOS 13, *)
public struct CheckoutStepStatusView_Previews: PreviewProvider {
    public static var previews: some View {
        Group {
            CheckoutStepStatusView(model: CheckoutStepStatus.loading)
                .previewLayout(.fixed(width: 100, height: 100))
                .preferredColorScheme(.light)
            
            CheckoutStepStatusView(model: CheckoutStepStatus.loading)
                .previewLayout(.fixed(width: 75, height: 75))
                .preferredColorScheme(.dark)
            
            CheckoutStepStatusView(model: CheckoutStepStatus.success)
                .previewLayout(.fixed(width: 25, height: 25))
                .preferredColorScheme(.light)
            
            CheckoutStepStatusView(model: CheckoutStepStatus.success)
                .previewLayout(.fixed(width: 50, height: 50))
                .preferredColorScheme(.light)
            
            CheckoutStepStatusView(model: CheckoutStepStatus.failure)
                .previewLayout(.fixed(width: 35, height: 35))
                .preferredColorScheme(.dark)
            
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
