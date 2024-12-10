//
//  VoucherItemView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 10.12.24.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding

struct VoucherItemView: View {
    let voucher: Voucher
    
    var body: some View {
        Text(keyed: voucher.scannedCode)
    }
}
