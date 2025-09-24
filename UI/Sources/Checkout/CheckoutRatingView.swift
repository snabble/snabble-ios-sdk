//
//  CheckoutRatingView.swift
//  UserFeedback
//
//  Created by Uwe Tilemann on 02.02.23.
//
import SwiftUI
import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents
import Combine
import Observation

struct RatingItem: Swift.Identifiable, Equatable {
    var id: String { rating.rawValue }
    var isActive: Bool = false
    let rating: RatingModel.Rating
    var image: SwiftUI.Image { isActive ? rating.imageSelect : rating.image }
}

@Observable
public final class RatingModel {
    public let shop: Shop
    public weak var analyticsDelegate: AnalyticsDelegate?

    public init(shop: Shop) {
        self.shop = shop
    }

    enum Rating: String, CaseIterable {
        case none
        case low
        case medium
        case high

        var value: Int {
            switch self {
            case .none:
                return 0
            case .low:
                return 1
            case .medium:
                return 2
            case .high:
                return 3
            }
        }
        var prompt: String {
            switch self {
            case .low, .medium:
                return Asset.localizedString(forKey: "Snabble.PaymentStatus.Ratings.feedbackPlaceholder")
            default:
                return ""
            }
        }
        var image: SwiftUI.Image {
            var anImage: SwiftUI.Image?
            
            switch self {
            case .low:
                anImage = Asset.image(named: "SnabbleSDK/emoji-1")
            case .medium:
                anImage = Asset.image(named: "SnabbleSDK/emoji-2")
            case .high:
                anImage = Asset.image(named: "SnabbleSDK/emoji-3")
            default:
                break
            }
            return anImage ?? SwiftUI.Image(systemName: "xmark")
        }
        var imageSelect: SwiftUI.Image {
            var anImage: SwiftUI.Image?
            
            switch self {
            case .low:
                anImage = Asset.image(named: "SnabbleSDK/emoji-1-select")
            case .medium:
                anImage = Asset.image(named: "SnabbleSDK/emoji-2-select")
            case .high:
                anImage = Asset.image(named: "SnabbleSDK/emoji-3-select")
            default:
                break
            }
            return anImage ?? SwiftUI.Image(systemName: "xmark")
        }
        var messageEnabled: Bool {
            [.low, .medium].contains(self)
        }
    }

    var ratingItems = [RatingItem(rating: .low), RatingItem(rating: .medium), RatingItem(rating: .high)]
    var selectionIndex: Int?
    var hasFeedbackSend: Bool = false
    
    var selectedRating: RatingItem? {
        guard let index = selectionIndex else { return nil }
        return ratingItems[index]
    }

    func tap(ratingItem: RatingItem) {
        guard let index = ratingItems.firstIndex(where: { $0.id == ratingItem.id }) else { return }
        
        selectionIndex = index
        for idx in ratingItems.indices {
            ratingItems[idx].isActive = (idx == index)
        }
        if selectedRating?.rating == .high {
            sendFeedback("")
        }
    }

    func sendFeedback(_ message: String) {
        guard let project = shop.project, let item = selectedRating else { return }
        
        print("send feedback: \(item) message: \(item.rating.messageEnabled ? message : "n/a")")
        RatingEvent.track(project, item.rating.value, item.rating.messageEnabled ? message : nil, shop.id)
        analyticsDelegate?.track(.ratingSubmitted(value: item.rating.value))
        hasFeedbackSend = true
    }
}

extension RatingModel {
    var ratingPrompt: String {
        return selectedRating?.rating.prompt ?? ""
    }
    var showTextEditor: Bool {
        return selectedRating?.rating.messageEnabled ?? false
    }
    var minHeight: CGFloat {
        return hasFeedbackSend ? 100 : (showTextEditor ? 256 : 128)
    }
}

struct RatingButton: View {
    var model: RatingModel
    var ratingItem: RatingItem
    
    var body: some View {
        Button(action: {
            withAnimation {
                model.tap(ratingItem: ratingItem)
            }
        }) {
            ratingItem.image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 52, maxHeight: 52)
        }
        .buttonStyle(AnimatedButtonStyle(selected: ratingItem.isActive))
    }
}

struct CheckoutRatingView: View {
    @State var model: RatingModel
    @ViewProvider(.ratingAccessory) var customView
    
    @State private var message: String = ""
    @State private var height: CGFloat = 0
    
    @ViewBuilder
    var textEditor: some View {
        if model.showTextEditor {
            VStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    if message.isEmpty {
                        UIKitTextView(text: .constant(model.ratingPrompt), font: .footnote)
                            .disabled(true)
                    }
                    UIKitTextView(text: $message, returnKeyType: .done, font: .body)
                        .opacity(message.isEmpty ? 0.25 : 1)
                }
                .cornerRadius(6)
                
                sendButton
                    .buttonStyle(ProjectPrimaryButtonStyle())
                    .disabled(model.selectionIndex == nil)
                
                customView
            }
        }
    }
    
    @ViewBuilder
    var ratingSelection: some View {
        HStack(spacing: 40) {
            ForEach(model.ratingItems, id: \.id) { item in
                RatingButton(model: model, ratingItem: item)
            }
        }
    }
    @ViewBuilder
    var sendButton: some View {
        Button(action: {
            withAnimation {
                model.sendFeedback(message)
            }
        }) {
            Text(keyed: "Snabble.PaymentStatus.Rating.send")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
        }
    }
    @ViewBuilder
    var stateContent: some View {
        if model.hasFeedbackSend {
            HStack {
                Text("🙏")
                    .font(.largeTitle)
                Text(keyed: "Snabble.PaymentStatus.Ratings.thanksForFeedback")
                    .font(.headline)
            }
        } else {
            VStack(spacing: 8) {
                Text(keyed: Asset.localizedString(forKey: "Snabble.PaymentStatus.Ratings.title"))
                    .font(.headline)
                    .frame(minHeight: 28)
                ratingSelection
                textEditor
            }
        }
    }
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            stateContent
        }
        .onChange(of: model.selectionIndex) {
            if model.showTextEditor, _customView.isAvailable {
                height = 40
            } else {
                height = 0
            }
        }
        .onChange(of: model.hasFeedbackSend) { _, newFeedback in
            if newFeedback {
                height = 0
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: model.minHeight + height, idealHeight: model.minHeight + height, maxHeight: model.minHeight + height)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
