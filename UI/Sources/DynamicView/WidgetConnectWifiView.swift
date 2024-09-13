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
import SnabbleCore
import SnabbleAssetProviding

final class ConnectWifiViewModel: ObservableObject {
    let configuration: DynamicViewConfiguration

    private let pathMonitor: NWPathMonitor

    init(configuration: DynamicViewConfiguration) {
        self.configuration = configuration

        pathMonitor = NWPathMonitor(requiredInterfaceType: .wifi)

        pathMonitor.pathUpdateHandler = { [weak self] _ in
            self?.isHidden = self!.verifyIsHidden()
        }
        pathMonitor.start(queue: .main)
    }

    deinit {
        pathMonitor.cancel()
    }

    // MARK: Published
    @Published var isHidden = true

    private func verifyIsHidden() -> Bool {
        guard !customerNetworks.isEmpty else {
            return true
        }
#if DEBUG
        return currentSSID == testSSID
#else
        if let currentSSID = currentSSID {
            return customerNetworks.contains(currentSSID)
        } else {
            return false
        }
#endif
    }

    @Published var isJoiningNetwork = false
    @Published var networkError: Error?
    
#if DEBUG
    let testSSID = "snabble"
#endif

    var canJoinNetwork: Bool {
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

            // after a short delay, try to access an url in the hope that
            // this forces any captive portal login screens to appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let testURL = URL(string: "https://captive.apple.com")!
                let captiveTask = URLSession.shared.dataTask(with: testURL) { _, response, error in
                    if error != nil {
                        DispatchQueue.main.async {
                            self?.networkError = error
                        }
                    }
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    print("got statuscode \(statusCode) from \(testURL)")
                }
                captiveTask.resume()
            }
        }
    }

    // MARK: Private Methods

    private var customerNetworks: [String] {
        let result = Snabble.shared.checkInManager.shop?.customerNetworks?.compactMap { $0.ssid } ?? []
        
#if DEBUG
        if result.isEmpty {
            return [testSSID]
        }
#endif
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

extension ConnectWifiViewModel {
    var text: String {
        guard let ssid = ssid else {
            return Asset.localizedString(forKey: "Snabble.DynamicView.ConnectWifi.noSSID")
        }
        return Asset.localizedString(forKey: "Snabble.DynamicView.connectWifi", arguments: ssid)
    }
}

public struct WidgetConnectWifiView: View {
    let widget: WidgetConnectWifi
    let configuration: DynamicViewConfiguration
    let action: (Widget) -> Void
    @ObservedObject private var viewModel: ConnectWifiViewModel

    init(widget: WidgetConnectWifi, configuration: DynamicViewConfiguration, action: @escaping (Widget) -> Void) {
        self.widget = widget
        self.configuration = configuration
        self.action = action

        self.viewModel = ConnectWifiViewModel(configuration: configuration)
    }
    
    @ViewBuilder
    var image: some View {
        if let image: SwiftUI.Image = Asset.image(named: "Snabble.DynamicView.connectWifi") {
            image
        } else {
            Asset.image(named: viewModel.networkError == nil ? "wifi" : "wifi.exclamationmark")
                .foregroundColor(.projectPrimary())
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
        if !viewModel.isHidden {
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
                action(widget)
            }
            .shadow(radius: configuration.shadowRadius)
        }
    }
}
