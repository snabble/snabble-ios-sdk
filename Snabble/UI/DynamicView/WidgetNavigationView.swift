//
//  WidgetNavigationView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 15.09.22.
//

import SwiftUI

public struct WidgetNavigationView: View {
    let widget: WidgetNavigation
    let action: (Widget) -> Void
    
    public var body: some View {
        WidgetTextView(
            widget: WidgetText(
                id: "1",
                text: widget.text,
                showDisclosure: true,
                spacing: widget.spacing
            )
        ).onTapGesture {
            action(widget)
        }
    }
}
