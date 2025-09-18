//
//  DependencyGraphTests.swift
//  Cestrum
//
//  Created by Wadÿe on 25/02/2025.
//

import Testing
import Foundation
@testable import CestrumCore

struct GraphTests {
    func constructTypicalGraph() -> DependencyGraph {
        let a = Deployment("A", .stopped)
        let b = Deployment("B", .stopped)
        let c = Deployment("C", .stopped)
        let d = Deployment("D", .stopped)
        
        let graph = try! DependencyGraph(name: "Typical_Graph", deployments: a, b, c, d) {
            a --> c
            a --> d
            b --> d
        }
        
        return graph
    }
    
    @Test
    func testConstruction() {
        let graph = constructTypicalGraph()
        print(graph)
    }
    
    @Test
    func testAdding() {
        let graph = constructTypicalGraph()
        graph.add("E", requirements: ["A"])
        print(graph)
        #expect(graph.dependencies.contains("E" --> "A"))
    }
    
    @Test
    func testRemoval() {
        let graph = constructTypicalGraph()
        graph.removeDeployment(named: "A")
        print(graph)
        #expect(!graph.dependencies.contains(where: { $0.contains("A") }))
    }
    
    @Test
    func testPlanGeneration() {
        let graph = constructTypicalGraph()
        
        print("\n\(graph)")
        
        let plan: AbstractFormula = [
            .remove("C"),
            .add("E", requirements: ["A"]),
            .replace(oldDeploymentName: "D", newDeployment: "D'"),
            .remove("D'"),
            .add("F", requirements: ["A"])
        ]
        
        let concretePlan = try! graph.generateConcretePlan(from: plan)
        
        print("\nABSTRACT")
        print(plan)
        
        print("\nCONCRETE")
        print(concretePlan)
    }
    
    @Test
    func testRemovePlan() throws {
        let a = Deployment("A")
        let b = Deployment("B")
        let c = Deployment("C")
        let d = Deployment("D")
        let e = Deployment("E")
        let f = Deployment("F")
        let g = Deployment("G")
        let h = Deployment("H")
        let i = Deployment("I")
        let newD = Deployment("D'")
        
        let graph = try DependencyGraph(name: "Example", deployments: [a, b, c, d, g, h, i]) {
            a --> [c, d]
            b --> d
            g --> h
            h --> i
        }
        
        print(graph)
        
        let plan: AbstractFormula = [
            .add(e, requirements: ["A"]),
            .remove("C"),
            .add(f, requirements: ["A", "B"]),
            .replace(oldDeploymentName: "D", newDeployment: newD)
        ]
        
        print(String(data: try! JSONEncoder.default.encode(graph.createCopy()), encoding: .utf8)!)
        
        let concretePlan = try! graph.generateConcretePlan(from: plan)
        concretePlan.apply(on: graph, onKubernetes: false)
        print(concretePlan)
        print(concretePlan.kubernetesEquivalent)
        print(graph)
    }
    
    @Test
    func testCESR() {
        let code =
        """
        configuration "Typical_Graph";
        add alpha "alpha.yaml" requiring {Z};
        bind Z to {A, B};
        add Z "z.yaml";
        remove C;
        replace D with ND "ND.yaml";
        add Y "path/to/manifest_of_Y.yaml";
        remove C;
        replace A with newA-A "ayham.yaml";
        unbind A from {ND};
        """
        
        let interpretationResult = CESRInterpreter.interpret(code: code)
        switch interpretationResult {
        case .success((let graphName, let abstractPlan)):
            print(graphName)
            print(">>>>>>>>>>>")
            print(abstractPlan)
            print(">>>>>>>>>>>")
            let graph = constructTypicalGraph()
            print(graph)
            do {
                let concretePlan = try graph.generateConcretePlan(from: abstractPlan)
                print(concretePlan)
                print(graph)
            } catch let error {
                print(error)
            }
        case .failure(let errors):
            for error in errors {
                if let line = error.line {
                    print(" | Line \(line): \(error.message)")
                } else {
                    print(" | \(error.message)")
                }
            }
        }
    }
    
    @Test
    func testParallelPlan() throws {
        let a = Deployment("A")
        let b = Deployment("B")
        let c = Deployment("C")
        let d = Deployment("D")
        let f = Deployment("F")
        
        let graph = try DependencyGraph(name: "Example", deployments: [a, b, c, d, f]) {
            a --> c
            b --> [c, d]
            f --> a
        }
        
        print(graph)
        
        let plan: AbstractFormula = [
            .remove("C"),
            .add("G", requirements: ["B"]),
            .bind(deploymentName: "A", requirementsNames: ["B"])
        ]
        
        let sequentialConcretePlan = try graph.generateConcretePlan(from: plan)
        
        print(sequentialConcretePlan)
        
        let targetGraph = try plan.createTargetGraph(from: graph)
        
        let workflow = ConcreteWorkflow(initialGraph: graph, targetGraph: targetGraph)
        print(workflow.dotTranslation)
    }
    
    @Test
    func testWorkflowConstructionAndExecution() async throws {
        let a = Deployment("A"); let c = Deployment("C")
        let b = Deployment("B"); let d = Deployment("D")
        let e = Deployment("E"); let f = Deployment("F")
        let g = Deployment("G")
        
        let graph = try DependencyGraph(name: "Graph", deployments: [a, b, c, d, e, f, g]) {
            a --> b
            e --> b
            b --> [f, c]
            c --> d
            g --> f
        }
        
        let formula: AbstractFormula = [
            .replace(oldDeploymentName: "F", newDeployment: "newF")
        ]
        
        let targetGraph = try formula.createTargetGraph(from: graph)
        let concreteWorkflow = ConcreteWorkflow(initialGraph: graph, targetGraph: targetGraph)
        
        print(concreteWorkflow.dotTranslation)
        
        try await concreteWorkflow.apply(on: graph)
    }
    
    @Test
    func testWorkflowRepair() async throws {
        let a = Deployment("A"); let b = Deployment("B");
        let c = Deployment("C"); let d = Deployment("D");
        let e = Deployment("E");
        
        let graph = try DependencyGraph(name: "graph", deployments: a, b, c, d, e) {
            a --> [b, c]
            b --> [d, e]
            c --> e
        }
        
        graph.fatalCheckForCycles()
        
        let formula: AbstractFormula = [
            .replace(oldDeploymentName: "E", newDeployment: "newE"),
            .replace(oldDeploymentName: "D", newDeployment: "newD")
        ]
        
        let targetGraph = try formula.createTargetGraph(from: graph)
        
        let workflow = ConcreteWorkflow(initialGraph: graph, targetGraph: targetGraph)
        
        print(workflow.dotTranslation)
        
        print("Non-compliant nodes: \(workflow.nodes.filter({ !$0.isCompliant }))")
        
        try await workflow.apply(on: graph)
    }
    
    @Test
    func testComplexWorkflowConstruction() async throws {
        let a = Deployment("A"); let b = Deployment("B");
        let c = Deployment("C"); let d = Deployment("D");
        let e = Deployment("E"); let f = Deployment("F");
        let g = Deployment("G"); let h = Deployment("H");
        let j = Deployment("J"); // let k = Deployment("K");
        let l = Deployment("L"); let m = Deployment("M");
        let n = Deployment("N");
        
        let graph = try DependencyGraph(name: "my_config", deployments: a, b, c, d, e, f, g, h, j, l, m, n) {
            [a, b, c, d, e] --> g
            e --> [b, c]
            [c, f] --> d
            f --> c
            h --> a
            g --> [l, m]
            a --> n
        }
        
        let code =
        """
        configuration "my_config";
        replace G with newG "newG.yaml";
        remove H;
        bind K to {E, F};
        replace J with newJ "newJ.yml";
        add K "k.yaml";
        """
        
        let result = CESRInterpreter.interpret(code: code)
        
        guard case .success(let interpretationContent) = result else {
            print("Interpretation failed")
            return
        }
        
        let formulaFromCode = interpretationContent.abstractPlan
        
        let targetGraph = try formulaFromCode.createTargetGraph(from: graph)
        
        let workflow = ConcreteWorkflow(initialGraph: graph, targetGraph: targetGraph)
        
        print(workflow.dotTranslation)
        
        try await workflow.apply(on: graph, forTesting: true)
    }
    
    @Test
    func testPresentationExample() async throws {
        let persistence = Deployment("persistence")
        let backend = Deployment("backend")
        let frontend = Deployment("frontend")
        let notificationService = Deployment("notification")
        let authService = Deployment("auth")
        
        let graph = try DependencyGraph(name: "my_config", deployments: persistence, frontend, backend, notificationService, authService) {
            [frontend, notificationService] --> backend
            backend --> [persistence, authService]
            authService --> persistence
        }
        
        let formula: AbstractFormula = [
            .replace(oldDeploymentName: "backend", newDeployment: Deployment("new-backend")),
            .replace(oldDeploymentName: "auth", newDeployment: Deployment("new-auth"))
        ]
        
        let targetGraph = try formula.createTargetGraph(from: graph)
        
        let workflow = ConcreteWorkflow(initialGraph: graph, targetGraph: targetGraph)
        
        print(workflow.dotTranslation)
    }
    
    @Test
    func testConfluentWorkflow() async throws {
        let persistence = Deployment("persistence")
        let backend = Deployment("backend")
        let frontend = Deployment("frontend")
        let notificationService = Deployment("notification")
        let authService = Deployment("auth")
        
        let graph = try DependencyGraph(name: "my_config", deployments: persistence, frontend, backend, notificationService, authService) {
            [frontend, notificationService] --> backend
            backend --> [persistence, authService]
            authService --> persistence
        }
        
        let formula: AbstractFormula = [
            .replace(oldDeploymentName: "backend", newDeployment: Deployment("new-backend")),
            .replace(oldDeploymentName: "auth", newDeployment: Deployment("new-auth"))
        ]
        
        let (targetGraph, complementaryInfo) = try formula.createTargetGraphWithComplementaryInformation(from: graph)
        
        let delta = Delta(sourceGraph: graph, targetGraph: targetGraph, complementaryInformation: complementaryInfo)
        
        let confluentPlan = ConfluentPlan(delta: delta)
        
        print(confluentPlan.workflow.dotTranslation)
    }
    
    @Test
    func testComplexConfluentPlan() async throws {
        let a = Deployment("A"); let b = Deployment("B");
        let c = Deployment("C"); let d = Deployment("D");
        let e = Deployment("E"); let f = Deployment("F");
        let g = Deployment("G"); let h = Deployment("H");
        let j = Deployment("J"); // let k = Deployment("K");
        let l = Deployment("L"); let m = Deployment("M");
        let n = Deployment("N");
        
        let graph = try DependencyGraph(name: "my_config", deployments: a, b, c, d, e, f, g, h, j, l, m, n) {
            [a, b, c, d, e] --> g
            e --> [b, c]
            [c, f] --> d
            f --> c
            h --> a
            g --> [l, m]
            a --> n
        }
        
        let code =
        """
        configuration "my_config";
        replace G with newG "newG.yaml";
        remove H;
        bind K to {E, F};
        replace J with newJ "newJ.yml";
        add K "k.yaml";
        """
        
        let result = CESRInterpreter.interpret(code: code)
        
        guard case .success(let interpretationContent) = result else {
            print("Interpretation failed")
            return
        }
        
        let formulaFromCode = interpretationContent.abstractPlan
        
        let (targetGraph, complmentaryInfo) = try formulaFromCode.createTargetGraphWithComplementaryInformation(from: graph)
        
        let delta = Delta(sourceGraph: graph, targetGraph: targetGraph, complementaryInformation: complmentaryInfo)
        let confluentPlan = ConfluentPlan(delta: delta)
        print(confluentPlan.workflow.dotTranslation)
//        try await workflow.apply(on: graph, forTesting: true)
    }
}
