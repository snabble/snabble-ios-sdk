//
//  DashboardWidget.swift
//  
//
//  Created by Uwe Tilemann on 30.08.22.
//

import SwiftUI

/// supported widget types
public enum WidgetType {
    case image
    case text
    case button
    case information
    case previousPurchases
}

/// A widget implements the `WidgetProvider` protocol
public protocol WidgetProvider: Swift.Identifiable {
    /// the widget type
    var type: WidgetType { get }
}

struct WidgetImage: WidgetProvider, ImageSourcing {
    var type: WidgetType {
        .image
    }
    var id: String
    let imageSource: String?
}

struct WidgetImageView: View {
    let widget: WidgetImage
    
    var body: some View {
        widget.image
    }
}

struct WidgetImageView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetImageView(widget: WidgetImage(id: "1", imageSource: "emoji-3"))
    }
}
