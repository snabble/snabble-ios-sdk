//
//  File.swift
//  Snabble
//
//  Created by Uwe Tilemann on 22.10.24.
//

import SwiftUI

import SnabbleCore
import SnabbleUI
import SnabbleAssetProviding
/*
    let isAnyActive = actions.contains { $0.active == true && $0.method.offline == false }

     let icon = isAnyActive && !(action.active || action.methodDetail != nil) ? action.icon?.grayscale() : action.icon

 */
public struct PaymentMethodItemView: View {
    
    var item: PaymentMethodItem
    var isActive: Bool
    
    public var body: some View {
        HStack {
            if let icon = item.icon {
                Image(uiImage: icon)
                    .blendMode(isActive ? .normal : .luminosity)
                    .opacity(isActive ? 1 : 0.8)
            }
            VStack(alignment: .leading) {
                Text(item.title)
                    .foregroundStyle(isActive ? .primary : .secondary)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

public struct PaymentSelectionView: View {
    var project: Project
    
    @State var items: [PaymentMethodItem] = []
    @State var isAnyActive = false
    @ScaledMetric var minHeight: CGFloat = 40

    public var body: some View {
            VStack(spacing: 10) {
                VStack {
                    Text(keyed: "Snabble.Shoppingcart.howToPay")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.top, 10)
                        .padding(.bottom, 5)
                    VStack(alignment: .leading) {
                        ForEach(items) { item in
                            Divider()
                            PaymentMethodItemView(item: item, isActive: !(isAnyActive && !(item.active || item.methodDetail != nil)))
                                .frame(height: minHeight)
                        }
                    }
                    .padding(.bottom, 10)
                }
                .background(RoundedRectangle(cornerRadius: 15).fill(.regularMaterial))
                .padding(.horizontal, 10)
                
                Button(action: {
                    
                }) {
                    HStack {
                        Spacer()
                        Text(keyed: "Snabble.cancel")
                        Spacer()
                    }
                }
                .padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: 15).fill(.regularMaterial))
                .padding(.horizontal, 10)
            }

            .onAppear {
            items = project.supportedPaymentMethodItems()
            isAnyActive = items.contains { $0.active == true && $0.method.offline == false }
        }
    }
}
