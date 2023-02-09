//
//  CheckoutStepStatusView.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 04.10.21.
//

import Foundation
import UIKit

protocol CheckoutStepStatusViewModel {
    var circleColor: UIColor? { get }
#if SWIFTUI_PROFILE
    var image: SwiftUI.Image? { get }
#else
    var image: UIImage? { get }
#endif
    var isLoading: Bool { get }
}

#if SWIFTUI_PROFILE
import SwiftUI

struct CheckoutStepStatusView: View {
    var model: CheckoutStepStatusViewModel
    var large: Bool = false

    var body: some View {
        ZStack {
            if let image = model.isLoading ? Image(systemName: "circle.fill") : model.image {
                image
                    .font(large ? .system(size: 152) : .headline)
                    .foregroundColor(Color(model.isLoading ? .secondarySystemGroupedBackground : model.circleColor ?? .secondarySystemGroupedBackground))
            }
            if model.isLoading {
                ProgressView()
            }
        }
    }
}
#else
final class CheckoutStepStatusView: UIView {
    private(set) weak var circleView: CircleView?
    private(set) weak var activityIndicatorView: UIActivityIndicatorView?
    private(set) weak var imageView: UIImageView?

    var circleColor: UIColor? {
        get {
            circleView?.backgroundColor
        }
        set {
            circleView?.backgroundColor = newValue
        }
    }

    override init(frame: CGRect) {
        let circleView = CircleView()
        circleView.translatesAutoresizingMaskIntoConstraints = false

        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.color = .systemGray

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemBackground
        imageView.contentMode = .scaleAspectFit

        super.init(frame: frame)

        addSubview(circleView)
        addSubview(activityIndicatorView)
        addSubview(imageView)

        self.circleView = circleView
        self.activityIndicatorView = activityIndicatorView
        self.imageView = imageView

        configure(with: CheckoutStepStatus.loading)

        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),

            circleView.widthAnchor.constraint(equalTo: circleView.heightAnchor),
            circleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: circleView.trailingAnchor),

            activityIndicatorView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),

            imageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: circleView.leadingAnchor),
            circleView.trailingAnchor.constraint(greaterThanOrEqualTo: imageView.trailingAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: circleView.topAnchor),
            circleView.bottomAnchor.constraint(greaterThanOrEqualTo: imageView.bottomAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            imageView.heightAnchor.constraint(equalTo: circleView.heightAnchor, multiplier: 0.56),

            circleView.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: circleView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CheckoutStepStatusViewModel) {
        imageView?.image = viewModel.image

        if viewModel.isLoading {
            circleView?.backgroundColor = circleColor ?? viewModel.circleColor
            activityIndicatorView?.startAnimating()
        } else {
            circleView?.backgroundColor = viewModel.circleColor
            activityIndicatorView?.stopAnimating()
        }
    }
}
#endif

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
    
#if SWIFTUI_PROFILE
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
#else
    var image: UIImage? {
        switch self {
        case .loading:
            return nil
        case .success:
            return UIImage(systemName: "checkmark")
        case .failure, .aborted:
            return UIImage(systemName: "xmark")
       }
    }
#endif
}

#if canImport(SwiftUI) && DEBUG && !SWIFTUI_PROFILE
import SwiftUI

@available(iOS 13, *)
public struct CheckoutStepStatusView_Previews: PreviewProvider {
    public static var previews: some View {
        Group {
            UIViewPreview {
                let view = CheckoutStepStatusView(frame: .zero)
                view.configure(with: CheckoutStepStatus.loading)
                return view
            }.previewLayout(.fixed(width: 100, height: 100))
                .preferredColorScheme(.light)
            UIViewPreview {
                let view = CheckoutStepStatusView(frame: .zero)
                view.configure(with: CheckoutStepStatus.loading)
                return view
            }.previewLayout(.fixed(width: 75, height: 75))
                .preferredColorScheme(.dark)
            UIViewPreview {
                let view = CheckoutStepStatusView(frame: .zero)
                view.configure(with: CheckoutStepStatus.success)
                return view
            }.previewLayout(.fixed(width: 25, height: 25))
                .preferredColorScheme(.light)
            UIViewPreview {
                let view = CheckoutStepStatusView(frame: .zero)
                view.configure(with: CheckoutStepStatus.success)
                return view
            }.previewLayout(.fixed(width: 50, height: 50))
                .preferredColorScheme(.light)
            UIViewPreview {
                let view = CheckoutStepStatusView(frame: .zero)
                view.configure(with: CheckoutStepStatus.failure)
                return view
            }.previewLayout(.fixed(width: 35, height: 35))
                .preferredColorScheme(.dark)
            UIViewPreview {
                let view = CheckoutHeaderView(frame: .zero)
                view.configure(with: CheckoutStepStatus.failure)
                return view
            }.previewLayout(.fixed(width: 100, height: 100))
                .preferredColorScheme(.dark)
            UIViewPreview {
                let view = CheckoutHeaderView(frame: .zero)
                view.configure(with: CheckoutStepStatus.failure)
                return view
            }.previewLayout(.fixed(width: 300, height: 300))
                .preferredColorScheme(.light)
        }
    }
}
#endif
