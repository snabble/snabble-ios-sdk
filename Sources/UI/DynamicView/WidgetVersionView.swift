//
//  WidgetVersionView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 15.09.22.
//

import SwiftUI

public struct WidgetVersionView: View {
    let widget: WidgetVersion
    let action: (Widget) -> Void
    
    public var body: some View {
        Text(widget.versionString).onTapGesture {
            action(widget)
        }
    }
}
