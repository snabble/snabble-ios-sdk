//
//  SnabbleMessage.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation
import SwiftMessages

public class SnabbleMessage {

    /// show a "toast" message underneath the status bar
    ///
    /// - Parameters:
    ///   - msg: the message to display
    ///   - theme: the theme to use, default: .info
    ///   - duration: the duration in seconds, default 3
    public static func showToast(msg: String, theme: Theme = .info, duration: Double = 3.0) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(theme)
        view.configureDropShadow()
        view.button?.isHidden = true
        view.iconLabel?.isHidden = true
        view.iconImageView?.isHidden = true
        view.titleLabel?.isHidden = true
        
        view.configureContent(body: msg)
        
        var config = SwiftMessages.defaultConfig
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        config.duration = .seconds(seconds: duration)
        
        SwiftMessages.hideAll()
        SwiftMessages.show(config: config, view: view)
    }

    /// show a "toast" message at the bottom of `viewController`
    ///
    /// - Parameters:
    ///   - msg: the message to display
    ///   - theme: the theme to use. default: .info
    ///   - duration: the duration in seconds, default 3
    ///   - viewController: the view controller in which to show the toast
    public static func showBottomToast(msg: String, theme: Theme = .info, duration: Double = 3.0, in viewController: UIViewController) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(theme)
        view.configureDropShadow()
        view.button?.isHidden = true
        view.iconLabel?.isHidden = true
        view.iconImageView?.isHidden = true
        view.titleLabel?.isHidden = true

        view.configureContent(body: msg)

        var config = SwiftMessages.defaultConfig
        config.presentationContext = .viewController(viewController)
        config.duration = .seconds(seconds: duration)
        config.presentationStyle = .bottom

        SwiftMessages.hideAll()
        SwiftMessages.show(config: config, view: view)
    }

    /// hide all currently shown messages (if any)
    public static func hideAll() {
        SwiftMessages.hideAll()
    }

    private class func create(layout: MessageView.Layout, theme: Theme) -> MessageView {
        let view = MessageView.viewFromNib(layout: layout)
        view.configureTheme(theme)
        view.configureDropShadow()
        return view
    }

}
