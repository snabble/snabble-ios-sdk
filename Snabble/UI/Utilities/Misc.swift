//
//  Misc.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//
//  Miscellaneous UI utility methods that don't warrant having their own source file

import UIKit

/// configuration parameters for the look of the view controllers in the Snabble SDK
public struct SnabbleAppearance {
    public var primaryColor = UIColor.black
    public var primaryBackgroundColor = UIColor.white
    public var secondaryColor = UIColor.white
    public var buttonShadowColor = UIColor.black
    public var buttonBorderColor = UIColor.black
    public var buttonBackgroundColor = UIColor.lightGray
    public var textColor = UIColor.black

    public init() {}
}

/// global settings for the Snabble UI classes
public class SnabbleUI {

    static var appearance = SnabbleAppearance()
    static var project = Project.none

    /// sets the global appearance to be used. Your app must call `SnabbleUI.setup()` before instantiating any snabble view controllers
    public static func setup(_ appearance: SnabbleAppearance) {
        self.appearance = appearance
    }

    /// sets the project to be used
    public static func register(_ project: Project) {
        self.project = project
    }
}

extension UIView {

    /// add a "rounded button" appearance to this view
    public func makeRoundedButton(cornerRadius: CGFloat? = nil) {
        self.layer.cornerRadius = cornerRadius ?? (self.frame.height / 2.0)
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowColor = SnabbleUI.appearance.buttonShadowColor.cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 2
    }

    /// add a "bordered button" appearance to this view
    public func makeBorderedButton() {
        self.layer.cornerRadius = 6
        self.backgroundColor = SnabbleUI.appearance.buttonBackgroundColor
        self.layer.borderWidth = 0.5
        self.layer.borderColor = SnabbleUI.appearance.buttonBorderColor.cgColor
    }

    /// add a "rounded card" appearance to this view
    public func addCornersAndShadow(backgroundColor: UIColor, cornerRadius: CGFloat) {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 4.0

        self.backgroundColor = UIColor.clear

        self.addBorderView(backgroundColor, cornerRadius)
    }

    @discardableResult
    private func addBorderView(_ bgColor: UIColor, _ cornerRadius: CGFloat) -> UIView {
        let borderView = UIView()
        borderView.backgroundColor = bgColor
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.layer.cornerRadius = cornerRadius
        borderView.layer.masksToBounds = true

        self.addSubview(borderView)

        borderView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        borderView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        borderView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        borderView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true

        self.sendSubviewToBack(borderView)

        return borderView
    }
}

public extension UIImage {

    /// use `self` as a mask to produce an image that only uses `color`
    ///
    /// used to generate icons suitable for use in a tabbar, since we can't use
    /// unselectedItemTintColor yet
    public func recolored(with color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()

        guard let context = UIGraphicsGetCurrentContext() else {
            return self
        }

        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)

        let rect = CGRect(origin: CGPoint.zero, size: self.size)
        context.clip(to: rect, mask: self.cgImage!)
        context.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!.withRenderingMode(.alwaysOriginal)
    }

}

/// Base class for UIViews that can be used directy in interface builder.
@IBDesignable
open class DesignableView: NibView {}

/// Base class for UIViews that can be instantiated from a NIB
open class NibView: UIView {
    var view: UIView!

    override public init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup(self.nibName)
        self.awakeFromNib()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup(self.nibName)
        self.awakeFromNib()
    }

    func nibSetup(_ nibName: String) {
        let nib = self.getNib(for: nibName)
        self.view = (nib.instantiate(withOwner: self, options: nil)[0] as! UIView)

        // use bounds not frame or it'll be offset
        self.view.frame = self.bounds

        // Add custom subview on top of our view
        self.addSubview(self.view)
        
        // Make the view stretch with the containing view
        // view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        self.translatesAutoresizingMaskIntoConstraints = false
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.view.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.view.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
    }

    func getNib(for name: String) -> UINib {
        let bundle = Bundle(for: type(of: self))
        if bundle.path(forResource: name, ofType: "nib") != nil {
            return UINib(nibName: name, bundle: bundle)
        } else {
            return UINib(nibName: name, bundle: Snabble.bundle)
        }
    }

    // override this if the name of the .xib file is not $CLASSNAME.xib
    open var nibName: String {
        return String(describing: type(of: self))
    }
}

@IBDesignable
class InsetLabel: UILabel {
    @IBInspectable var topInset: CGFloat = 0
    @IBInspectable var leftInset: CGFloat = 0
    @IBInspectable var bottomInset: CGFloat = 0
    @IBInspectable var rightInset: CGFloat = 0

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width+leftInset+rightInset, height: size.height+topInset+bottomInset)
    }
}

// MARK: - l10n and image support

class Snabble: NSObject {
    private static let frameworkBundle = Bundle(for: Snabble.self)
    static let path = frameworkBundle.path(forResource: "Snabble", ofType: "bundle")!
    static let bundle = Bundle(path: path)!
}

extension String {
    func localized() -> String {
        // check if the app has localized this string
        let upper = self.uppercased()
        let appValue = Bundle.main.localizedString(forKey: self, value: upper, table: nil)
        if appValue != upper {
            return appValue
        }
        let sdkValue = Snabble.bundle.localizedString(forKey: self, value: upper, table: "SnabbleLocalizable")
        return sdkValue
    }
}

extension UIImage {
    /// get an image from our snabble bundle
    static func fromBundle(_ name: String) -> UIImage? {
        return UIImage(named: name, in: Snabble.bundle, compatibleWith: nil)
    }
}
