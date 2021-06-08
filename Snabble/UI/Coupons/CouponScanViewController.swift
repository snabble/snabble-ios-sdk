//
//  CouponScanViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

// TODO: L10n
// TODO: torch toggle / code entry?

import UIKit

final class CouponScanViewController: UIViewController {
    private let detector = BuiltinBarcodeDetector(detectorArea: .rectangle, messageDelegate: nil)
    private let cameraPreview = UIView()
    private var lastScannedCode: String?
    private var timer: Timer?

    private weak var delegate: CouponDelegate?

    init(delegate: CouponDelegate?) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.title = "Coupons scannen"
        self.view.backgroundColor = .systemBackground

        detector.delegate = self
        detector.scanFormats = [.ean13, .code128]

        cameraPreview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraPreview)

        NSLayoutConstraint.activate([
            cameraPreview.topAnchor.constraint(equalTo: view.topAnchor),
            cameraPreview.rightAnchor.constraint(equalTo: view.rightAnchor),
            cameraPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cameraPreview.leftAnchor.constraint(equalTo: view.leftAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        detector.scannerWillAppear(on: cameraPreview)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        detector.scannerDidLayoutSubviews()
    }

    override func viewDidAppear(_ animated: Bool) {
        delegate?.track(.viewCouponScan)
        super.viewDidAppear(animated)

        detector.resumeScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        detector.pauseScanning()
        detector.scannerWillDisappear()
    }
}

extension CouponScanViewController: BarcodeDetectorDelegate {
    func scannedCode(_ code: String, _ format: ScanFormat) {
        guard code != lastScannedCode else {
            return
        }

        print("got \(code)")
        lastScannedCode = code
        startLastScanTimer()

        let feedback = UINotificationFeedbackGenerator()
        if let coupon = checkValidCoupon(code) {
            let wallet = CouponWallet.shared
            if wallet.contains(coupon) {
                feedback.notificationOccurred(.error)
                delegate?.showInfoMessage("Diesen Coupon hast du schon gescannt")
            } else {
                feedback.notificationOccurred(.success)
                delegate?.showInfoMessage("Coupon \"\(coupon.name)\" ist jetzt verfügbar")
                wallet.add(coupon)
                delegate?.track(.couponScanned)
            }
        } else {
            feedback.notificationOccurred(.error)
            delegate?.showWarningMessage("Kein gültiger Coupon-Code erkannt")
        }
    }

    func track(_ event: AnalyticsEvent) {
        delegate?.track(event)
    }

    private func startLastScanTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            self.lastScannedCode = nil
        }
    }

    private func checkValidCoupon(_ scannedCode: String) -> Coupon? {
        for project in SnabbleAPI.projects {
            for coupon in project.printedCoupons {
                for code in coupon.codes ?? [] {
                    let result = CodeMatcher.match(scannedCode, project.id)
                    if result.first(where: { $0.template.id == code.template && $0.lookupCode == code.code }) != nil {
                        return coupon
                    }
                }
            }
        }
        return nil
    }
}
