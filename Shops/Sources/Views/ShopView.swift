//
//  ShopView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import SwiftUI

import SnabbleCore
import SnabbleComponents
import SnabbleAssetProviding
import SnabbleTheme

extension CheckInManager {
    func shop(for provider: any ShopProviding) -> Shop? {
        return projects
            .flatMap({ $0.shops })
            .first(where: { $0.id == provider.id })
    }
    
    func isCheckedIn(for provider: any ShopProviding) -> Bool {
        return shop?.id == provider.id
    }
    
    public func verifyDeveloperCheckin() {
        if DeveloperMode.showCheckIn, let checkInShopId = UserDefaults.standard.string(forKey: DeveloperMode.Keys.checkInShop.rawValue) {
            if let shop = projects
                .flatMap({ $0.shops })
                .first(where: { "\($0.id)" == checkInShopId }) {
                developerCheckin(at: shop)
            }
        }
    }

    func developerCheckin(at fakeShop: any ShopProviding, persist: Bool = false) {
        if persist {
            UserDefaults.standard.set("\(fakeShop.id)", forKey: DeveloperMode.Keys.checkInShop.rawValue)
        }
        stopUpdating()
        shop = shop(for: fakeShop)
    }

    func developerCheckout() {
        UserDefaults.standard.removeObject(forKey: DeveloperMode.Keys.checkInShop.rawValue)

        shop = nil
        startUpdating()
    }
}

public extension DeveloperMode {

    // returns true if an alert should be shown to set:
    //   Snabble.shared.checkInManager.developerCheckin(at: shop, persist: false|true)
    // return false and checkout if was previolsly checkedin
    static func toggleCheckIn(for shop: any ShopProviding) -> Bool {
        guard showCheckIn else {
            return false
        }

        if Snabble.shared.checkInManager.isCheckedIn(for: shop) {
            Snabble.shared.checkInManager.developerCheckout()
            return false
        } else {
            return true
        }
    }
}

public struct ShopView: View {
    @SwiftUI.Environment(\.projectTrait) private var project

    var shop: any ShopProviding

    @State var viewModel: ShopsViewModel
    @State private var showingAlert = false
    @State private var showingCheckin = false

    @ViewBuilder
    var distance: some View {        
        if viewModel.isCurrent(shop) {
            Button(action: {
                viewModel.actionPublisher.send(shop)
            }) {
                Text(keyed: "Snabble.Shop.Detail.shopNow")
            }
            .buttonStyle(ProjectPrimaryButtonStyle())
        } else {
            HStack {
                Spacer()
                Image(systemName: "location")
                    .font(.subheadline)
                    .foregroundColor(.systemGray)
                DistanceView(distance: viewModel.distance(from: shop))
                Button(action: {
                    showingAlert.toggle()
                }) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.projectPrimary())
                }
                .navigateToShopAlert(isPresented: $showingAlert, shop: shop)
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    var checkInButton: some View {
        if DeveloperMode.showCheckIn {
            Button(action: {
                showingCheckin = DeveloperMode.toggleCheckIn(for: shop)
            }) {
                Text(isCheckedIn() ? "[Check Out]" : "[Check In]")
            }
            .alert(
                "Check in",
                isPresented: $showingCheckin,
                presenting: "Text"
            ) { details in
                Button(role: .destructive) {
                    Snabble.shared.checkInManager.developerCheckin(at: shop, persist: false)
                } label: {
                    Text("This Session")
                }
                Button(role: .destructive) {
                    Snabble.shared.checkInManager.developerCheckin(at: shop, persist: true)
                } label: {
                    Text("Until next check out")
                }
            } message: { details in
                Text(details)
            }
        }
    }
    
    public var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {
                ShopMapView(shop: shop, showNavigationControl: true)
                    .frame(minHeight: 300)

                VStack(spacing: 0) {
                    checkInButton
                    AddressView(provider: shop)
                }
                .font(.body)

                distance
                    .font(.body)

                PhoneNumberView(phone: shop.phone)
                    .font(.body)

                OpeningHoursView(shop: shop)
            }
        }
        .navigationTitle(shop.name)
    }
    
    private func isCheckedIn() -> Bool {
        return Snabble.shared.checkInManager.state.shop?.id == self.shop.id
    }
}
