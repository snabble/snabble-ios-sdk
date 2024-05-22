//
//  AccountStateView.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 04.04.23.
//

import SwiftUI
import SnabblePay

struct AccountStateView: View {
    @ObservedObject var viewModel: AccountViewModel
    @State private var showMandate = false
    
    var canToggleHTML: Bool {
       return viewModel.mandateState == .accepted && viewModel.htmlText != nil
    }

    @ViewBuilder
    var mandatePending: some View {
        if let mandate = viewModel.mandate {
            VStack {
                mandateState
                    .padding()
                
                if let markup = viewModel.markup {
                    HTMLView(string: markup)
                }
                VStack {
                    Button {
                        viewModel.accept(mandateId: mandate.id)
                    } label: {
                        Text("Accept")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .padding([.leading, .trailing])
                    Button {
                        viewModel.decline(mandateId: mandate.id)
                    } label: {
                        Text("Decline")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .padding([.leading, .trailing])
                }
                .padding(.bottom)
           }
            .padding([.leading, .trailing])
        }
    }
    
    @ViewBuilder
    var mandateState: some View {
        HStack {
            viewModel.mandateStateImage
                .foregroundStyle(.white, viewModel.mandateStateColor, viewModel.mandateStateColor)
            Text(viewModel.mandateStateString)
            if canToggleHTML {
                Button(action: {
                    withAnimation {
                        showMandate.toggle()
                    }
                }) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.white, viewModel.mandateStateColor, viewModel.mandateStateColor)
                }
            }
        }
    }
    
    @ViewBuilder
    var mandateInfo: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    mandateState
                        .font(.headline)
                    Spacer()
                }
                .padding([.top, .leading, .trailing])
                .padding(.bottom, viewModel.mandate != nil ? 0 : 20)

                if viewModel.mandate != nil {
                    Text(viewModel.mandateIDString)
                        .foregroundColor(.secondary)
                        .font(.footnote)
                        .padding([.bottom], 8)
                    
                    if showMandate, let markup = viewModel.markup {
                        HTMLView(string: markup)
                    }
                }
            }
        }
        .onTapGesture {
            if canToggleHTML {
                withAnimation {
                    showMandate.toggle()
                }
            }
        }
        .padding([.leading, .trailing])
    }

    var body: some View {
        if viewModel.mandateState == .missing {
            HStack {
                Text("No Mandate")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                    .padding()
            }
            .padding([.leading, .trailing])
        } else {
            if viewModel.mandateState == .pending {
                mandatePending
            } else {
                mandateInfo
            }
        }
    }
}
