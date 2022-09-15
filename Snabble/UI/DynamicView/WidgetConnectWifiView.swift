//
//  WidgetConnectWifiView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 14.09.22.
//

import SwiftUI
import SystemConfiguration.CaptiveNetwork
import NetworkExtension
import Combine
import Network

protocol WifiHintViewData {
    var text: String { get }
}

final class WidgetConnectWifiViewModel: ObservableObject {
    private let pathMonitor: NWPathMonitor

    init() {
        pathMonitor = NWPathMonitor(requiredInterfaceType: .wifi)

        pathMonitor.pathUpdateHandler = { [weak self] _ in
            self?.isHidden = self!.verifyIsHidden()
            self?.viewData = self
        }
        pathMonitor.start(queue: .main)
    }

    deinit {
        pathMonitor.cancel()
    }

    // MARK: Published

    @Published var viewData: WifiHintViewData?
    @Published var isHidden = true

    private func verifyIsHidden() -> Bool {
//        guard !BuildConfig.simulator else {
//            return true
//        }

        guard !customerNetworks.isEmpty else {
            return true
        }

        guard !isTesting else {
            return false
        }

        if let currentSSID = currentSSID {
            return customerNetworks.contains(currentSSID)
        } else {
            return false
        }
    }

    @Published var isJoiningNetwork = false
    @Published var networkError: Error?
    
    var isTesting: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    var canJoinNetwork: Bool {
        guard !isTesting else {
            return true
        }

        guard let ssid = ssid, currentSSID != ssid else {
            return false
        }
        return true
    }
    
    @objc func joinNetwork() {
        guard let ssid = ssid, canJoinNetwork else {
            return
        }

        let config = NEHotspotConfiguration(ssid: ssid)
        config.joinOnce = false
        isJoiningNetwork = true
        NEHotspotConfigurationManager.shared.apply(config) { [weak self] error in
            self?.isJoiningNetwork = false

            self?.networkError = error

            // after a short delay, try to access https://snabble.io in the hope that
            // this forces any captive portal login screens to appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                let snabbleURL = URL(string: "https://httpbin.org/status/200" /*"/https://snabble.io"*/)!
                let captiveTask = URLSession.shared.dataTask(with: snabbleURL) { _, response, _ in
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    print("got statuscode \(statusCode) from \(snabbleURL)")
                }
                captiveTask.resume()
            }
        }
    }

    // MARK: Private Methods

    private var customerNetworks: [String] {
        let result = Snabble.shared.checkInManager.shop?.customerNetworks?.compactMap { $0.ssid } ?? []
        
        if isTesting, result.isEmpty {
            return ["snabble"/*"SnapNet"*/]
        }
        return result
    }

    private var ssid: String? {
        customerNetworks.first
    }

    /// get the SSID of the wifi network we're currently connected to
    private var currentSSID: String? {
        (CNCopySupportedInterfaces() as? [String])?
            .compactMap { interfaceInfo(from: $0) }
            .first
    }

    /// get the ssid for a particular interface
    private func interfaceInfo(from interface: String) -> String? {
        guard
            let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: AnyObject],
            let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
        else {
            return nil
        }

        return ssid
    }
}

extension WidgetConnectWifiViewModel: WifiHintViewData {
    var text: String {
        return Asset.localizedString(forKey: "Snabble.DynamicView.wifi", arguments: ssid ?? "unkown" )
    }
}

public struct WidgetConnectWifiView: View {
    let widget: WidgetConnectWifi
    let shadowRadius: CGFloat
    @ObservedObject private var viewModel = WidgetConnectWifiViewModel()
    
    @ViewBuilder
    var image: some View {
        if let image: SwiftUI.Image = Asset.image(named: "Snabble.DynamicView.wifi" ) {
            image
        } else {
            Asset.image(named: viewModel.networkError == nil ? "wifi" : "wifi.exclamationmark")
                .foregroundColor(.accent())
                .font(.title)
        }
    }

    @ViewBuilder
    var status: some View {
        if let error = viewModel.networkError {
            Text(error.localizedDescription)
                .font(.footnote)
                .foregroundColor(.systemRed)
        }
    }
    
    public var body: some View {
        if widget.isVisible {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text(keyed: viewModel.text)
                        .font(.subheadline)
                    status
                }
                Spacer()
                ZStack {
                    image
                        .opacity(viewModel.isJoiningNetwork ? 0.2 : 1)
                    ProgressView()
                        .opacity(viewModel.isJoiningNetwork ? 1 : 0)
                }
            }
            .informationStyle()
            .onTapGesture {
                viewModel.joinNetwork()
            }
            .shadow(radius: shadowRadius)
        }
    }
}