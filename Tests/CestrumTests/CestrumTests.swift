//
//  DependencyGraphTests.swift
//  Cestrum
//
//  Created by Wadÿe on 25/02/2025.
//

import Testing
@testable import CestrumKit

struct GraphTests {
    func constructTypicalGraph() -> DependencyGraph {
        let a = Deployment("A", .stopped)
        let b = Deployment("B", .stopped)
        let c = Deployment("C", .stopped)
        let d = Deployment("D", .stopped)
        
        let graph = DependencyGraph(name: "Typical_Graph", deployments: a, b, c, d) {
            a --> c
            a --> d
            b --> d
        }
        
        graph.boot()
        
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
        #expect(graph.arcs.contains("E" --> "A"))
    }
    
    @Test
    func testRemoval() {
        let graph = constructTypicalGraph()
        graph.remove("A")
        print(graph)
        #expect(!graph.arcs.contains(where: { $0.contains("A") }))
    }
    
    @Test
    func testPlanGeneration() {
        let graph = constructTypicalGraph()
        
        print("\n\(graph)")
        
        let plan: AbstractPlan = [
            .remove("C"),
            .add("E", requirements: ["A"]),
            .replace(oldDeployment: "D", newDeployment: "D'"),
            .remove("D'"),
            .add("F", requirements: ["A"])
        ]
        
        let (abstractPlan, intermediatePlan, concretePlan) = graph.generatePlans(from: plan)
        
        print("\nABSTRACT")
        print(abstractPlan)
        
        print("\nINTERMEDIATE")
        print(intermediatePlan)
        
        print("\nCONCRETE")
        print(concretePlan)
    }
    
    @Test
    func testRemovePlan() {
        let a = Deployment("A")
        let b = Deployment("B")
        let c = Deployment("C")
        let d = Deployment("D")
        let e = Deployment("E")
        let f = Deployment("F")
        // let g = Deployment("G")
        let newD = Deployment("D'")
        
        let graph = DependencyGraph(name: "Example", deployments: [a, b, c, d]) {
            a --> [c, d]
            b --> d
        }
        
        print(graph)
        
        let plan: AbstractPlan = [
            .add(e, requirements: [a]),
            .add(f, requirements: [a, b]),
            .remove(c),
            .replace(oldDeployment: d, newDeployment: newD)
        ]
        
        let (abstractPlan, intermediatePlan, concretePlan) = graph.generatePlans(from: plan)
        
        print("\nABSTRACT")
        print(abstractPlan)
        
        print("\nINTERMEDIATE")
        print(intermediatePlan)
        
        print("\nCONCRETE")
        print(concretePlan)
        
        print("\nNEW GRAPH AFTER APPLICATION")
        concretePlan.apply(on: graph, onKubernetes: false)
        print(graph)
    }
    
    @Test
    func testCESP() {
        let code =
        """
        hook "G";
        add Z "z.yaml" requiring {A, B};
        remove C;
        replace D with ND "ND.yaml";
        """
        
        let lexer = CESPLexer(input: code)
        var tokens = try! lexer.tokenise()
        tokens = tokens.filter { !$0.kind.isDisposable }
        print(tokens)
        let analyser = CESPAnalyser(tokens: tokens)
        analyser.analyse()
        let translator = CESPTranslator(tokens: tokens)
        let (graphName, abstractPlan) = translator.translate()
        print(graphName)
        print(">>>>>>>>>>>")
        print(abstractPlan)
        print(">>>>>>>>>>>")
        print(constructTypicalGraph().generatePlans(from: abstractPlan).concrete)
    }
}
