//
//  CheckoutInformationView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 06.02.23.
//
import SwiftUI
import Combine

protocol CheckoutInformationViewModel {
    var text: String { get }
    var actionTitle: String? { get }
    var userInfo: [String: Any]? { get }
}

struct CheckoutInformationView: View {
    var model: CheckoutInformationViewModel
    @Environment(CheckoutModel.self) private var checkoutModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.text)
                .onTapGesture {
                    if model.actionTitle == nil {
                        checkoutModel.actionPublisher.send(model.userInfo)
                    }
                }
            if let title = model.actionTitle {
                Button(action: {
                    checkoutModel.actionPublisher.send(["action": title])
                }) {
                    Text(title)
                        .foregroundColor(.systemRed)
                }
            }
        }
        .font(.footnote)
    }
}

extension CheckoutStep: CheckoutInformationViewModel {}

#if DEBUG
extension CheckoutInformationView {
    struct ViewModel: CheckoutInformationViewModel {
        let text: String
        let actionTitle: String?
        var userInfo: [String: Any]?
        
        static var mock: Self {
            .init(
                text: "Möchtest du die Daten deiner girocard sicher in der App speichern, um deinen nächsten Einkauf per Lastschrift zu bezahlen? Die Karte kannst du zukünftig im Geldbeutel lassen.",
                actionTitle: "Ja, Daten in der App speichern"
            )
        }
    }
}

public struct CheckoutInformationView_Previews: PreviewProvider {
    public static var previews: some View {
        Group {
            CheckoutInformationView(model: CheckoutInformationView.ViewModel.mock)
                .previewLayout(.fixed(width: 300, height: 300))
                .preferredColorScheme(.dark)
            CheckoutInformationView(model: CheckoutInformationView.ViewModel.mock)
                .previewLayout(.fixed(width: 300, height: 300))
                .preferredColorScheme(.light)
        }
    }
}
#endif
