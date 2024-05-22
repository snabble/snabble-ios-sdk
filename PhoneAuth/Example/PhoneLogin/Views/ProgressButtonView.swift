//
//  ProgressButtonView.swift
//  teo
//
//  Created by Uwe Tilemann on 06.02.24.
//

import SwiftUI

struct ProgressButtonView: View {
    let title: String
    @Binding var showProgress: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Text(title)
                    .fontWeight(.bold)
                
                if showProgress {
                    ProgressView()
                        .padding([.leading], 10)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
