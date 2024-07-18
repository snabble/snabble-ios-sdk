//
//  ShopperLoadingView.swift
//  Quartier
//
//  Created by Uwe Tilemann on 04.07.24.
//

import SwiftUI

public struct ShopperLoadingView: View {
    public init() { }
    
    public var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.gray)
            ScannerProcessingView()
        }
    }
}

#Preview {
    ShopperLoadingView()
}
