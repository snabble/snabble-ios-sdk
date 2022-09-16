//
//  WidgetVersionView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 15.09.22.
//

import SwiftUI

public struct WidgetVersionView: View {
    var widget: WidgetVersion
    
    public var body: some View {
        Text(widget.versionString)
    }
}
