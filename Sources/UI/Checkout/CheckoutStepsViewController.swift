//
//  CheckoutStepsViewController.swift
//  Snabble
//
//  Created by Uwe Tilemann on 06.02.23.
//
import SnabbleCore
import SwiftUI
import Combine

struct CheckoutStepItem: Swift.Identifiable, Equatable {
    let id = UUID()
    let checkoutStep: CheckoutStep
}

final class CheckoutModel: ObservableObject {

    weak var paymentDelegate: PaymentDelegate? {
        didSet {
            self.ratingModel.analyticsDelegate = paymentDelegate
        }
    }
    var actionPublisher = PassthroughSubject<[String: Any]?, Never>()

    @Published var stepsModel: CheckoutStepsViewModel
    @Published var isComplete: Bool = false
    @Published var checkoutSteps: [CheckoutStepItem] = []
    
    let ratingModel: RatingModel

    init(stepsModel: CheckoutStepsViewModel) {
        self.stepsModel = stepsModel
        self.ratingModel = RatingModel(shop: stepsModel.shop)
    }
    
    func update(checkoutSteps: [CheckoutStep]) {
        var array = [CheckoutStepItem]()
        
        for step in checkoutSteps {
            array.append(CheckoutStepItem(checkoutStep: step))
        }
        self.checkoutSteps = array
    }
    
    func isLast(step: CheckoutStepItem) -> Bool {
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
    var step: CheckoutStepItem
    
    var body: some View {
        switch step.checkoutStep.kind {
        case .default:
            CheckoutStepView(model: step.checkoutStep)
        case .information:
            CheckoutInformationView(model: step.checkoutStep)
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
    @State private var showCustom = true
    @State private var count = 1

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
                .padding(.top, 50)
                .onTapGesture {
                    showCustom.toggle()
                }
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(model.checkoutSteps) { step in
                    CheckoutStepRow(step:step).environmentObject(model)
                        .padding(10)
                    
                    if !model.isLast(step: step) {
                        Divider()
                            .padding(.leading, 40)
                    }
                }
            }
            .background(Color.secondarySystemGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding([.leading, .trailing], 20)
            .shadow(color: Color("Shadow"), radius: 6, x: 3, y: 3)
            
        }
    }
    
    @ViewBuilder
    var button: some View {
        Button(action: {
            model.done()
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Spacer()
                Text(Asset.localizedString(forKey: "Snabble.done"))
                    .fontWeight(.bold)
                Spacer()
            }
        }
        .buttonStyle(AccentButtonStyle())
        .padding([.leading, .trailing], 20)
    }

    var body: some View {
        ZStack(alignment: .top) {
            if model.isComplete {
                customView
            }
            VStack(spacing: 0) {
                GeometryReader { geom in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            topContent
                                .background(GeometryReader {
                                    Color.clear
                                        .preference(key: ViewHeightKey.self, value: $0.frame(in: .local).size.height)
                                })
                                .onPreferenceChange(ViewHeightKey.self) {
                                    self.height1 = $0
                                }
                            
                            VStack(spacing: 0) {
                                CheckoutRatingView(model: model.ratingModel)
                                    .padding(20)
                                    .shadow(color: Color("Shadow"), radius: 6, x: 3, y: 3)
                                Spacer()
                                
                                button
                                .background(GeometryReader {
                                        Color.clear
                                            .preference(key: ViewHeightKey.self, value: $0.frame(in: .local).size.height)
                                    })
                            }
                            .frame(height: max(geom.size.height - self.height1, self.height2))
                        }
                    }
                    .onPreferenceChange(ViewHeightKey.self) {
                        self.height2 = $0
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .edgesIgnoringSafeArea(.top)
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

    init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess?) {
        let stepsModel = CheckoutStepsViewModel(
            shop: shop,
            checkoutProcess: checkoutProcess,
            shoppingCart: shoppingCart
        )
        
        self.model = CheckoutModel(stepsModel: stepsModel)
        
        super.init(rootView: CheckoutView(model: self.model))
        stepsModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.model.actionPublisher
            .sink { [unowned self] info in
                if info?["action"] != nil {
                    self.stepAction()
                }
            }
            .store(in: &cancellables)

        self.model.update(checkoutSteps: viewModel.steps)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.startTimer()
        paymentDelegate?.track(.viewCheckoutSteps)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @objc func stepAction() {
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
