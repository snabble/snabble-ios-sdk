//
//  CredentialsView.swift
//  SnabblePayExample
//
//  Created by Uwe Tilemann on 23.02.23.
//

import SwiftUI
import SnabblePay
import Combine
import BetterSafariView

struct AccountsView: View {
    @ObservedObject var viewModel: AccountsViewModel = .init()
    @ObservedObject var errorHandler: ErrorHandler = .shared

    @State private var reset: Bool = false

    @State private var animationStarted = false
    @State private var animationOffset: CGFloat = 0
    @State private var zIndex: Double = 0
    @State private var showError = false
    
    let inTime = 0.35
    let outTime = 0.25
    let cardOffset = 60
    
    private var cardPosition: CGFloat {
        CGFloat(cardOffset * (viewModel.accounts?.count ?? 0))
    }
    private func slidePosition(index: Int) -> CGFloat {
        CGFloat((cardOffset * index) * -1) - CGFloat(viewModel.isSelected(index: index) ? animationOffset : 0.0)
    }
    private func startAnimationOffset(index: Int) -> CGFloat {
        CGFloat((((viewModel.accounts?.count ?? 1) - (index + 1)) * cardOffset) * -1)
    }
    private func tapGesture(account: Account, index: Int) -> some Gesture {
        LongPressGesture(minimumDuration: 0.05)
                .onChanged { _ in
                    if viewModel.canSelect, !animationStarted {
                        withAnimation(.easeIn(duration: inTime)) {
                            animationStarted = true
                            animationOffset = startAnimationOffset(index: index)
                            zIndex = 300
                            viewModel.selectedAccount = account
                        }
                    }
                }
    }

    @ViewBuilder
    private func cardView(account: Account) -> some View {
        if viewModel.selectedAccount == account, let model = viewModel.selectedAccountModel {
                NavigationLink {
                    AccountView(accountsModel: viewModel)
                } label: {
                    CardView(model: model)
                }
        } else {
            CardView(account: account, expand: false)
        }
    }

    @ViewBuilder
    var header: some View {
        VStack {
            Image("Title")
            Text("The Future of Mobile Payment")
                .foregroundColor(.accentColor)
        }
        .shadow(radius: 3)
        .shadow(radius: 3)
    }

    var body: some View {
        NavigationStack {
            if let ordered = viewModel.ordered, !ordered.isEmpty {
                ZStack {
                    BackgroundView()
                    VStack {
                        header
                            .padding(.top, 36)
                        
                        ScrollView(.vertical) {
                            ZStack(alignment: .center) {
                                ForEach(Array(ordered.enumerated()), id: \.offset) { index, account in
                                    cardView(account: account)
                                        .slideEffect(offset: slidePosition(index: index))
                                        .gesture(tapGesture(account: account, index: index))
                                        .zIndex(viewModel.isSelected(index: index) ? 200 : zIndex)
                                }
                            }
                            .offset(y: cardPosition)
                        }
                    }
                }
                .confirmationDialog("Reset all accounts", isPresented: $reset, titleVisibility: .visible) {
                    Button("Reset", role: .destructive) {
                        SnabblePay.reset()
                        viewModel.loadAccounts()
                    }
                }
                .onChange(of: animationStarted) { value in
                    if value == true {
                        DispatchQueue.main.asyncAfter(deadline: .now() + inTime + 0.1) {
                            withAnimation(.easeOut(duration: outTime)) {
                                animationStarted = false
                                animationOffset = 0
                                zIndex = 0
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + inTime + 0.15) {
                                    viewModel.selectedAccountModel?.refresh()
                                }
                            }
                        }
                    }
                }
                
                .toolbar {
                    if errorHandler.error != nil {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                viewModel.loadAccounts()
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                            }
                        }
                    } else {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                viewModel.startAccountCheck()
                            }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            reset.toggle()
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                }
            } else {
                ZStack {
                    BackgroundView()
                    VStack {
                        header
                            .padding(.top, 80)
                        
                        AddFirstAccount(viewModel: viewModel)
                            .padding(.top, 100)

                        Spacer()
                   }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.loadAccounts()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                        }
                    }
                }
                .onAppear {
                    viewModel.loadAccounts()
                }
            }
        }
        .onChange(of: errorHandler.error) { error in
            if error != nil {
                showError = true
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text(errorHandler.error?.localizedAction ?? "Error"),
                  message: Text(errorHandler.error?.localizedReason ?? "An error occured"))
        }
        .preferredColorScheme(.dark)
        .edgesIgnoringSafeArea(.all)
        .sheet(
            item: $viewModel.accountCheck,
            content: { accountCheck in
                // User: u98235448, Password: cdz248
                // User: u86382190, Password: gmg612
                SafariView(url: accountCheck.validationURL)
            }
        )
        .onOpenURL {
            #warning("check appURI")
            print("appURI: ", $0.absoluteString)
            viewModel.accountCheck = nil
            viewModel.loadAccounts()
        }
    }
}
