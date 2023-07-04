//
//  PaymentSubjectViewModel.swift
//  
//
//  Created by Uwe Tilemann on 30.06.23.
//

import Foundation
import Combine

public class PaymentSubjectViewModel: ObservableObject {
    @Published public var subject: String?
    @Published public var isValid: Bool = false
    
    public var debounce: RunLoop.SchedulerTimeType.Stride = 0.5
    public var minimumInputCount: Int = 4
    
    private var cancellables = Set<AnyCancellable>()

    private var isSubjectValidPublisher: AnyPublisher<Bool, Never> {
        $subject
            .debounce(for: debounce, scheduler: RunLoop.main)
            .minimumOptional(minimumInputCount)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    public let actionPublisher = PassthroughSubject<[String: Any]?, Never>()
    
    public enum Action: String {
        case add
        case skip
        case cancel
    }
    public init() {
        isSubjectValidPublisher
            .assign(to: \.isValid, onWeak: self)
            .store(in: &cancellables)

    }
    public func add() {
        actionPublisher.send(["action": Action.add.rawValue])
    }
    public func skip() {
        actionPublisher.send(["action": Action.skip.rawValue])
    }
    public func cancel() {
        actionPublisher.send(["action": Action.cancel.rawValue])
    }
}
