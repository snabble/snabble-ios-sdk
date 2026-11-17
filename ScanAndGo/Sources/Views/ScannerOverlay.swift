//
//  ScannerOverlay.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

import SnabbleAssetProviding

public struct ScannerOverlay: View {
    @Binding public var offset: CGFloat

    @State var overlay: SwiftUI.Image = Asset.image(named: "SnabbleSDK/barcode-overlay")!

    public init(offset: Binding<CGFloat>) {
        self._offset = offset
    }

    public var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                overlay
                Spacer()
            }
            .padding(.bottom, offset)
            Spacer()
        }
    }
}
