//
//  MethodProjects.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

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

        if SnabbleAPI.debugMode {
            RawPaymentMethod.allCases.filter { $0.editable && methodMap[$0] == nil }.forEach {
                methodMap[$0] = ["TEST"]
            }
        }

        return methodMap
            .map { MethodProjects(method: $0, projectNames: $1) }
            .sorted { $0.method.order > $1.method.order }
    }
}
