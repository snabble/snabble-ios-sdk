//
//  Misc.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//
//  Miscellaneous UI utility methods that don't warrant having their own source file

import UIKit
import SnabbleAssetProviding
import SnabbleComponents

extension UIButton {
    /// add a "rounded button" appearance to this button
    public func makeSnabbleButton() {
        self.layer.cornerRadius = CGFloat.primaryButtonRadius()
        self.backgroundColor = .projectPrimary()
        self.setTitleColor(.onProjectPrimary(), for: .normal)
        self.tintColor = .onProjectPrimary()
    }

    /// add a "bordered button" appearance to this button
    public func makeBorderedButton() {
        self.layer.cornerRadius = 6
        self.backgroundColor = .secondarySystemBackground
        self.layer.borderWidth = 1 / UIScreen.main.scale
        self.layer.borderColor = UIColor.border().cgColor
    }
}

extension UIView {
    /// add a "rounded card" appearance to this view
    public func addCornersAndShadow(backgroundColor: UIColor, cornerRadius: CGFloat) {
        self.layer.shadowColor = UIColor.shadow().cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 2.0

        self.backgroundColor = .clear

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
    func recolored(with color: UIColor) -> UIImage {
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

    /// create a grayscale version of `self`
    func grayscale(brightness: Double = 0.0, contrast: Double = 1.0) -> UIImage? {
        guard let cgImage = self.cgImage else {
            return nil
        }

        let inputImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIColorControls")
        let params: [String: Any] = [
            kCIInputImageKey: inputImage,
            kCIInputBrightnessKey: brightness,
            kCIInputContrastKey: contrast,
            kCIInputSaturationKey: 0.0
        ]
        filter?.setValuesForKeys(params)

        guard
            let outputImage = filter?.outputImage,
            let filteredImage = CIContext().createCGImage(outputImage, from: outputImage.extent)
        else {
            return nil
        }

        return UIImage(cgImage: filteredImage, scale: self.scale, orientation: self.imageOrientation)
    }
}

extension UIImage {
    /// get an image from either the main or our snabble bundle
    static func fromBundle(_ name: String?) -> UIImage? {
        guard let name = name else {
            return nil
        }

        // try the main bundle first
        if let img = UIImage(named: name, in: Bundle.main, compatibleWith: nil) {
            return img
        }
#if SWIFT_PACKAGE
        return UIImage(named: name, in: Bundle.module, compatibleWith: nil)
#else
        return UIImage(named: name, in: SnabbleSDKBundle.main, compatibleWith: nil)
#endif
    }
}

extension UIApplication {
    class func topViewController(_ base: UIViewController? = UIApplication.shared.sceneKeyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }

    class func topNavigationController() -> UINavigationController? {
        return topViewController()?.navigationController
    }
}

extension UINavigationController {
    /// pop to the top-most instance of the given UIViewController, or one where it is a child viewController
    /// If none found, pop one level
    func popToInstanceOf(_ instanceType: UIViewController.Type, animated: Bool) {
        if let target = self.findTarget(of: instanceType) {
            self.popToViewController(target, animated: animated)
        } else {
            self.popViewController(animated: animated)
        }
    }

    private func findTarget(of instanceType: UIViewController.Type) -> UIViewController? {
        if let instance = self.viewControllers.first(where: { type(of: $0) == instanceType }) {
            return instance
        }

        if let parent = self.viewControllers.flatMap({ $0.children }).first(where: { type(of: $0) == instanceType })?.parent {
            return parent
        }

        return nil
    }
}
