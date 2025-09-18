//
//  File.swift
//  CestrumCore
//
//  Created by Wadÿe on 16/09/2025.
//

import Foundation

/// A plan that enables parallel execution
public struct ConfluentPlan {
    /// The (parallelisable) workflow that represents this plan.
    public let workflow: ConcreteWorkflow
    
    init(delta: Delta) {
        let constraintSet = OrderingConstraintSet.confluentSet(from: delta)
        let (nodes, naiveFlows) = delta.extractNodesAndFlows(constraints: constraintSet)
        let workflow = ConcreteWorkflow(nodes: nodes, naiveFlows: naiveFlows)
        workflow.groupBothEnds()
        workflow.wrap()
        self.workflow = workflow
    }
    
    /// Generates a confluent parallelisable plan following the given abstract formula.
    public init(graph: DependencyGraph, formula: AbstractFormula) throws(RuntimeError) {
        let (targetGraph, complementaryInfo) = try formula.createTargetGraphWithComplementaryInformation(from: graph)
        let delta = Delta(sourceGraph: graph, targetGraph: targetGraph, complementaryInformation: complementaryInfo)
        let constraintSet = OrderingConstraintSet.confluentSet(from: delta)
        let (nodes, naiveFlows) = delta.extractNodesAndFlows(constraints: constraintSet)
        let workflow = ConcreteWorkflow(nodes: nodes, naiveFlows: naiveFlows)
        workflow.groupBothEnds()
        workflow.wrap()
        self.workflow = workflow
    }
}

