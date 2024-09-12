//
//  CheckoutStepsViewController.swift
//  Snabble
//
//  Created by Uwe Tilemann on 06.02.23.
//
import SnabbleCore
import SwiftUI
import Combine
import SnabbleAssetProviding

final class CheckoutModel: ObservableObject {

    weak var paymentDelegate: PaymentDelegate? {
        didSet {
            self.ratingModel.analyticsDelegate = paymentDelegate
        }
    }
    var actionPublisher = PassthroughSubject<[String: Any]?, Never>()

    @Published var stepsModel: CheckoutStepsViewModel
    @Published var isComplete: Bool = false
    @Published var checkoutSteps: [CheckoutStep] = []

    var isSuccessful: Bool {
        guard let paymentState = stepsModel.checkoutProcess?.paymentState else {
            return false
        }
        return PaymentState.successStates.contains(paymentState)
    }
    
    let ratingModel: RatingModel

    init(stepsModel: CheckoutStepsViewModel) {
        self.stepsModel = stepsModel
        self.ratingModel = RatingModel(shop: stepsModel.shop)
    }
    
    func update(checkoutSteps: [CheckoutStep]) {
        self.checkoutSteps = checkoutSteps
    }
    
    func isLast(step: CheckoutStep) -> Bool {
        guard let last = checkoutSteps.last else {
            return false
        }
        return step == last
    }
    
    func done() {
        Snabble.shared.fetchAppUserData(self.stepsModel.shop.projectId)
        updateShoppingCart(for: self.stepsModel.checkoutProcess)
        paymentDelegate?.checkoutFinished(self.stepsModel.shoppingCart, self.stepsModel.checkoutProcess)
        paymentDelegate?.track(.checkoutStepsClosed)
        
        actionPublisher.send(["action": "done"])
    }

    private func updateShoppingCart(for checkoutProcess: CheckoutProcess?) {
        switch checkoutProcess?.paymentState {
        case .successful, .transferred:
            self.stepsModel.shoppingCart.removeAll(endSession: true, keepBackup: false)
        default:
            self.stepsModel.shoppingCart.generateNewUUID()
        }
    }
}

struct CheckoutStepRow: View {
    var step: CheckoutStep

    var body: some View {
        switch step.kind {
        case .default:
            CheckoutStepView(model: step)
        case .information:
            CheckoutInformationView(model: step)
        }
    }
}

private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct CheckoutView: View {
    @ObservedObject var model: CheckoutModel
    @Environment(\.presentationMode) var presentationMode
    @ViewProvider(.successCheckout) var customView
    
    @State private var height1: CGFloat = .zero
    @State private var height2: CGFloat = .zero

    init(model: CheckoutModel) {
        self.model = model
        
        if #unavailable(iOS 16.0) {
            UITableView.appearance().backgroundColor = .clear
        }
    }
    
    @ViewBuilder
    var topContent: some View {
        VStack {
            CheckoutHeaderView(model: model.stepsModel.headerViewModel)
                .padding(.top, 10)
            
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(model.checkoutSteps, id: \.self) { step in
                    CheckoutStepRow(step: step)
                        .environmentObject(model)
                        .padding(10)
                    
                    if !model.isLast(step: step) {
                        Divider()
                            .padding(.leading, 40)
                    }
                }
            }
            .background(Color.secondarySystemGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.leading, .trailing], 20)
            .shadow(radius: 8, x: 0, y: 4)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                if model.isSuccessful {
                    customView
                        .edgesIgnoringSafeArea(.top)
                }
                ScrollView(.vertical, showsIndicators: false) {
                    topContent
                    
                    if model.isSuccessful {
                        CheckoutRatingView(model: model.ratingModel)
                            .padding(20)
                            .shadow(radius: 8, x: 0, y: 4)
                    }
                }

                VStack {
                    Spacer()
                    Button(action: {
                        model.done()
                    }) {
                        Text(Asset.localizedString(forKey: "Snabble.PaymentStatus.close"))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!model.isComplete)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding([.bottom, .horizontal], 16)
                }

            }
        }
    }
}

final class CheckoutStepsViewController: UIHostingController<CheckoutView> {
    
    weak var paymentDelegate: PaymentDelegate? {
        didSet {
            self.model.paymentDelegate = paymentDelegate
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    let model: CheckoutModel

    var viewModel: CheckoutStepsViewModel {
        self.model.stepsModel
    }

    init(model: CheckoutModel) {
        self.model = model
        
        super.init(rootView: CheckoutView(model: self.model))
        viewModel.delegate = self
    }
    
    convenience init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess?) {
        let stepsModel = CheckoutStepsViewModel(
            shop: shop,
            checkoutProcess: checkoutProcess,
            shoppingCart: shoppingCart
        )
        self.init(model: CheckoutModel(stepsModel: stepsModel))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.model.actionPublisher
            .sink { [weak self] info in
                self?.stepAction(userInfo: info)
            }
            .store(in: &cancellables)
#if MOCK_CHECKOUT
        self.model.update(checkoutSteps: CheckoutStep.mockModel)
#else
        self.model.update(checkoutSteps: viewModel.steps)
#endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if !MOCK_CHECKOUT
        viewModel.startTimer()
#endif
        paymentDelegate?.track(.viewCheckoutSteps)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @objc func stepAction(userInfo: [String: Any]?) {
        if let userInfo = userInfo {
            if let action = userInfo["action"] as? String, action == "done" {
                navigationController?.popToRootViewController(animated: false)
            }
            if let receiptLink = userInfo["receiptLink"] as? SnabbleCore.Link, let url = URL(string: receiptLink.href) {
                let detailViewController = ReceiptsDetailViewController(orderId: url.lastPathComponent, projectId: viewModel.shop.projectId)
                navigationController?.pushViewController(detailViewController, animated: true)
                return
            }
        }
        
        guard let originCandidate = viewModel.originCandidate else { return }
        if let project = Snabble.shared.project(for: viewModel.shop.projectId),
           project.paymentMethodDescriptors.first(where: { $0.acceptedOriginTypes?.contains(.payoneSepaData) ?? false }) != nil {
            let sepaViewController = SepaDataEditViewController(viewModel: SepaDataModel(iban: originCandidate.origin, projectId: viewModel.shop.projectId))
            sepaViewController.delegate = self
            navigationController?.pushViewController(sepaViewController, animated: true)
        } else {
            let sepaViewController = SepaEditViewController(originCandidate, paymentDelegate)
            sepaViewController.delegate = self
            navigationController?.pushViewController(sepaViewController, animated: true)
        }
    }
}

extension CheckoutStepsViewController: CheckoutStepsViewModelDelegate {
    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateCheckoutProcess checkoutProcess: CheckoutProcess) {
        self.model.isComplete = checkoutProcess.isComplete
        
        if checkoutProcess.isComplete {
            Snabble.clearInFlightCheckout()
        } else if checkoutProcess.paymentState == .unauthorized && checkoutProcess.links.authorizePayment != nil {
            guard self.presentedViewController == nil || self.presentedViewController?.isKind(of: SepaAcceptViewController.self) == false else {
                return
            }
            let paymentDetail = PaymentMethodDetail.paymentDetailFor(rawMethod: checkoutProcess.rawPaymentMethod)
            let sepaCheckViewController = SepaAcceptViewController(viewModel: SepaAcceptModel(process: checkoutProcess, paymentDetail: paymentDetail))
            
            self.present(sepaCheckViewController, animated: true)
        }
    }

    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateSteps steps: [CheckoutStep]) {
        self.model.update(checkoutSteps: steps)
    }

    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateHeaderViewModel headerViewModel: CheckoutHeaderViewModel) { }

    func checkoutStepsViewModel(_ viewModel: CheckoutStepsViewModel, didUpdateExitToken exitToken: ExitToken) {
        paymentDelegate?.exitToken(exitToken, for: viewModel.shop)
    }
}

extension CheckoutStepsViewController: SepaEditViewControllerDelegate {
    func sepaEditViewControllerDidSave(iban: String) {
        viewModel.savedIbans.insert(iban)
        viewModel.update()
    }
}

extension CheckoutStepsViewController: SepaDataEditViewControllerDelegate {
    func sepaDataEditViewControllerWillSave(_ viewController: SepaDataEditViewController, userInfo: [String: Any]?) {
        viewController.sepaDataEditViewControllerWillSave(viewController, userInfo: userInfo)
        viewModel.update()
    }
}
