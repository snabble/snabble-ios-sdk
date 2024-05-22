//
//  CardView.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 23.02.23.
//

import SwiftUI
import SnabblePay

struct CardView: View {
    @ObservedObject var model: AccountViewModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme

    private let expand: Bool
    
    @State private var toggleSize = false
    @State private var topAnimation = false
    @State private var opactiyOn = 1.0
    @State private var opactiyOff = 0.0

    init(model: AccountViewModel, expand: Bool = false) {
        self.model = model
        self.expand = expand
    }

    init(account: Account, expand: Bool = false) {
        self.model = AccountViewModel(account: account, autostart: false)
        self.expand = expand
    }
 
    @ViewBuilder
    var mandateState: some View {
        if !self.expand, model.mandateState != .accepted {
            HStack {
                model.mandateStateImage
                    .foregroundStyle(.white, model.mandateStateColor, model.mandateStateColor)
                Text(model.mandateStateString)
            }
        }
    }
    
    @ViewBuilder
    var qrImage: some View {
        if let token = model.token {
            QRCodeView(code: token.value)
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .foregroundColor(.secondary)
        }
    }
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer(minLength: 0)
            mandateState
            qrImage
                .padding([.top])
                .frame(width: toggleSize ? 160 : 60)
            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text(model.ibanString)
                    .font(.custom("Menlo", size: 16))
                    .fontWeight(.bold)
                HStack {
                    Text(model.account.holderName)
                    Spacer()
                    if topAnimation {
                        ZStack(alignment: .trailing) {
                            Text(model.customName)
                                .opacity(opactiyOn)
                            Text(model.account.bank)
                                .opacity(opactiyOff)
                        }
                        
                   } else {
                       Text(expand || !model.hasCustomName ? model.account.bank : model.customName)
                    }
                }
                .font(.caption)
            }
            .padding([.leading, .trailing], 20)
            .padding([.bottom], 10)
        }
        .foregroundColor(Color.black)
        .cardStyle(top: model.autostart)
        .onChange(of: scenePhase) { newPhase in
            guard model.autostart else {
                return
            }
            if newPhase == .active {
                model.refresh()
            } else if newPhase == .background {
                model.sleep()
            }
        }
        .onAppear {
            if model.autostart, !expand {
                let baseAnimation = Animation.easeInOut(duration: 1).delay(5)
                let repeated = baseAnimation.repeatForever(autoreverses: true)
                topAnimation = true
                
                withAnimation(repeated) {
                    opactiyOn = 0.0
                    opactiyOff = 1.0
                }
            }
            
            withAnimation {
                self.toggleSize = self.expand || self.model.token != nil
            }
        }
        .onChange(of: model.sessionUpdated) { _ in
            withAnimation {
                toggleSize = model.autostart
            }
        }
    }
}
