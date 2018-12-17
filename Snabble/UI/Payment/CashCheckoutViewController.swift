//
//  CashCheckoutViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

final class CashCheckoutViewController: UIViewController {

    @IBOutlet var steps: [UIView]!
    @IBOutlet var spinners: [UIActivityIndicatorView]!
    @IBOutlet weak var checkoutIdLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    
    private weak var cart: ShoppingCart!
    private weak var delegate: PaymentDelegate!

    private var currentStep = 0
    private var process: CheckoutProcess
    private var poller: PaymentProcessPoller?

    init(_ process: CheckoutProcess, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        self.process = process
        self.cart = cart
        self.delegate = delegate
        
        super.init(nibName: nil, bundle: Snabble.bundle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Snabble.Checkout.title".localized()

        self.steps.forEach { view in
            view.backgroundColor = .white
            view.subviews.forEach { subview in
                if let label = subview as? UILabel {
                    label.textColor = .black
                }
            }
        }

        self.navigationItem.hidesBackButton = true

        self.checkoutIdLabel.text = "Snabble.Checkout.ID".localized() + ": " + String(process.links.`self`.href.suffix(4))
        self.cancelButton.setTitle("Snabble.Cancel".localized(), for: .normal)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.delegate.track(.viewCashCheckout)
        
        self.spinners[0].startAnimating()

        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
            self?.locationAquired()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.poller = nil
    }

    private func locationAquired() {
        self.switchColors(0)

        self.spinners[1].startAnimating()
        self.spinners[2].startAnimating()

        self.poller = PaymentProcessPoller(self.process, SnabbleUI.project, self.cart.config.shop)

        self.poller?.waitFor([ .approval ]) { events in
            if let success = events[.approval] {
                if success {
                    self.switchColors(1) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.switchColors(2)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.paymentFinished(true)
                            }
                        }
                    }
                } else {
                    self.paymentFinished(false)
                }
            }
        }
    }

    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.poller?.stop()
        self.poller = nil

        self.delegate.track(.paymentCancelled)

        self.process.abort(SnabbleUI.project) { result in
            self.navigationController?.popToRootViewController(animated: true)
        }
    }

    private func paymentFinished(_ success: Bool) {
        self.poller = nil
        if success {
            self.cart.removeAll()
        }
        self.delegate.paymentFinished(success, self.cart)
    }

    private func switchColors(_ index: Int, completion: (()->())? = nil) {
        let view = self.steps[index]
        let duration: TimeInterval = 0.25

        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut))

        CATransaction.setCompletionBlock {
            self.spinners[index].stopAnimating()
            completion?()
        }

        self.curtainAnimation(view, duration)
        
        let animationOptions: UIView.AnimationOptions = [ .transitionCrossDissolve, .curveEaseInOut, .allowAnimatedContent ]
        view.subviews.forEach { subview in
            if let label = subview as? UILabel {
                UIView.transition(with: label, duration: duration, options: animationOptions , animations: {
                    label.textColor = SnabbleUI.appearance.secondaryColor
                }, completion: nil)
            }
            if let img = subview as? UIImageView {
                UIView.transition(with: img, duration: duration, options: animationOptions, animations: {
                    img.image = img.image?.recolored(with: SnabbleUI.appearance.secondaryColor)
                }, completion: nil)
            }
        }

        CATransaction.commit()
    }

    private func curtainAnimation(_ view: UIView, _ duration: TimeInterval) {
        let size = view.frame.size

        let startPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: 0))
        let endPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let rectangleLayer = CAShapeLayer()
        rectangleLayer.path = startPath.cgPath
        rectangleLayer.fillColor = SnabbleUI.appearance.primaryColor.cgColor
        rectangleLayer.zPosition = -1
        view.layer.addSublayer(rectangleLayer)

        let growAnimation = CABasicAnimation()
        growAnimation.keyPath = "path"
        growAnimation.duration = duration
        growAnimation.toValue = endPath.cgPath
        growAnimation.fillMode = CAMediaTimingFillMode.forwards
        growAnimation.isRemovedOnCompletion = false
        growAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        rectangleLayer.add(growAnimation, forKey: "grow")
    }

}


