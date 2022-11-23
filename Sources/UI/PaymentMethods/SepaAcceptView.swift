//
//  SepaAcceptView.swift
//  
//
//  Created by Uwe Tilemann on 23.11.22.
//

import SwiftUI

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
    var button: some View {
        Button(action: {
            model.actionPublisher.send(["action": "accept"])
        }) {
            Text(keyed: "Snabble.SEPA.iAgree")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(AccentButtonStyle())
    }
    
    public var body: some View {
        VStack {
            text
            button
        }
        .padding()
    }
    
}
