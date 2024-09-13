//
//  SepaAcceptView.swift
//  
//
//  Created by Uwe Tilemann on 23.11.22.
//

import SwiftUI
import SnabbleComponents

public struct SepaAcceptView: View {
    @ObservedObject public var model: SepaAcceptModel

    public init(model: SepaAcceptModel) {
        self.model = model
    }
    
    @ViewBuilder
    var text: some View {
        if let markup = model.markup {
            HTMLView(string: markup)
        } else {
            Text(keyed: "Snabble.SEPA.mandate")
        }
    }
    
    @ViewBuilder
    var acceptButton: some View {
        Button(action: {
            model.actionPublisher.send(["action": "accept"])
        }) {
            Text(keyed: "Snabble.SEPA.iAgree")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ProjectPrimaryButtonStyle())
    }
    
    @ViewBuilder
    var declineButton: some View {
        Button(action: {
            model.actionPublisher.send(["action": "decline"])
        }) {
            Text(keyed: "Snabble.SEPA.iDoNotAgree")
                .frame(maxWidth: .infinity)
        }
    }

    public var body: some View {
        VStack {
            text
            acceptButton
            declineButton
        }
        .padding()
    }
    
}
