//
//  MethodProjects.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

@available(*, deprecated)
public struct MethodProjects {
    public let method: RawPaymentMethod
    public let projectNames: [String]

    public static func initialize() -> [MethodProjects] {
        let allPaymentMethods = SnabbleAPI.projects.reduce(into: []) { result, project in
            result.append(contentsOf: project.paymentMethods)
        }
        let paymentMethods = Set(allPaymentMethods.filter({ $0.editable }))

        var methodMap = [RawPaymentMethod: [String]]()
        for method in paymentMethods {
            for prj in SnabbleAPI.projects {
                if prj.paymentMethods.contains(method) {
                    methodMap[method, default: []].append(prj.name)
                }
            }
        }

        return methodMap
            .map { MethodProjects(method: $0, projectNames: $1) }
            .sorted { $0.method.displayName < $1.method.displayName }
    }
}
