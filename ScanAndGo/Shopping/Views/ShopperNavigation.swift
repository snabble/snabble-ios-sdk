//
//  ShopperNavigation.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 04.07.24.
//

import SwiftUI
import SnabbleComponents

extension String {
    static func errorString(reason: String) -> String {
        "\(reason)\nThis should not happen! 😳"
    }
}
struct ErrorText: View {
    let reason: String
    
    var body: some View {
        Text(String.errorString(reason: reason))
    }
}

struct InvalidNavigationView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Spacer()
            ErrorText(reason: "Invalid Navigation")
            Spacer()
        }
        .onTapGesture {
            dismiss()
        }
    }
    
    /// Dismisses the toast and the full screen cover animated
    private func dismiss() {
        withAnimation {
            isPresented = false
        }
    }
}

extension Shopper {
    @ViewBuilder
    public func navigationDestination(isPresented: Binding<Bool>) -> some View {
        if let controller {
            ContainerView(viewController: controller, isPresented: isPresented)
                .navigationTitle(controller.navigationItem.title ?? "Navigation")
        } else {
            InvalidNavigationView(isPresented: isPresented)
        }
    }
}

#Preview {
    InvalidNavigationView(isPresented: .constant(true))
}
