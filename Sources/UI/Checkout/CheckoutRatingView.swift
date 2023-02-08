//
//  CheckoutRatingView.swift
//  UserFeedback
//
//  Created by Uwe Tilemann on 02.02.23.
//
import SwiftUI
import SnabbleCore

struct RatingItem: Swift.Identifiable, Equatable {
    var id: String { rating.rawValue }
    var isActive: Bool = false
    let rating: RatingModel.Rating
}

public final class RatingModel: ObservableObject {
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
            case .low:
                return Asset.localizedString(forKey: "Snabble.PaymentStatus.Rating.title")
            case .medium:
                return Asset.localizedString(forKey: "Snabble.PaymentStatus.Rating.title2")
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
        var messageEnabled: Bool {
            [.low, .medium].contains(self)
        }
    }

    @Published var ratingItems = [RatingItem(rating: .low), RatingItem(rating: .medium), RatingItem(rating: .high)]
    @Published var selectionIndex: Int?
    @Published var hasFeedbackSend: Bool = false
    
    var selectedRating: RatingItem? {
        guard let index = selectionIndex else { return nil }
        return ratingItems[index]
    }

    func tap(ratingItem: RatingItem) {
        guard let index = ratingItems.firstIndex(where: { $0.id == ratingItem.id } ) else { return }
        
        selectionIndex = index
        for i in ratingItems.indices {
            ratingItems[i].isActive = (i == index)
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
        return hasFeedbackSend ? 80 : (showTextEditor ? 225 : 150)
    }
}

struct RatingButton: View {
    var model: RatingModel
    var ratingItem: RatingItem
    @State var selected = false
    
    var body: some View {
        Button(action: {
            withAnimation {
                model.tap(ratingItem: ratingItem)
                selected = ratingItem.isActive
            }
        }) {
            ratingItem.rating.image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 40, maxHeight: 40)
        }
        .buttonStyle(AnimatedButtonStyle(selected: selected))
    }
}

struct CheckoutRatingView: View {
    @ObservedObject var model: RatingModel
    @ViewProvider("custom-rating") var customView
    
    @State private var message: String = ""
    @State private var height: CGFloat = 0

    @ViewBuilder
    var textEditor: some View {
        if model.showTextEditor {
            ZStack(alignment: .leading) {
                if message.isEmpty {
                    UIKitTextView(text: .constant(model.ratingPrompt), font: .footnote)
                        .disabled(true)
                }
                UIKitTextView(text: $message, returnKeyType: .done, font: .body)
                    .opacity(message.isEmpty ? 0.25 : 1)
            }
            .cornerRadius(6)
       }
    }
    @ViewBuilder
    var ratingSelection: some View {
        HStack(spacing: 40) {
            ForEach(model.ratingItems, id: \.id) { item in
                RatingButton(model: model, ratingItem: item)
                    .scaleEffect(item == model.selectedRating ? 1.3 : 1)
            }
        }
        .padding([.top, .bottom], 8)
    }
    @ViewBuilder
    var sendButton: some View {
        Button(action: {
            model.sendFeedback(message)
        }) {
            HStack {
                Spacer()
                Text(keyed: "Snabble.PaymentStatus.Rating.send")
                    .fontWeight(.bold)
                Spacer()
            }
        }
    }
    @ViewBuilder
    var stateContent: some View {
        if model.hasFeedbackSend {
            VStack(spacing: 0) {
                Text(keyed: "Snabble.PaymentStatus.Ratings.thanks")
                Spacer()
            }
        } else {
            VStack(spacing: 8) {
                ratingSelection
                textEditor
                sendButton
                    .buttonStyle(AccentButtonStyle())
                    .disabled(model.selectionIndex == nil)
            }
        }
    }
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(keyed: Asset.localizedString(forKey: "Snabble.PaymentStatus.Ratings.title"))
                .font(.headline)
            stateContent
            customView
        }
        .onAppear {
            if _customView.isAvailable {
                height = 40
            }
        }
        .frame(minWidth: 300, minHeight: model.minHeight + height, idealHeight: model.minHeight + height, maxHeight: model.minHeight + height)
        .padding([.leading, .trailing, .bottom], 20)
        .padding([.top], 10)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color("Shadow"), radius: 8, x: 4, y: 4)
    }
}
