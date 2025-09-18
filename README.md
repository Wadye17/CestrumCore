This is the core framework consisting of protocols, classes, enumerations and structures that model and describe configurations,
abstract operations and specifications, concrete operations and plans, as well as the CESR language interpreter.

# Requirements
- A Unix or Windows operating system
- [Swift 6.0 or later](https://www.swift.org/install/macos/)
- Intermediate-to-advanced knowledge of Swift
- Kubernetes with a working cluster—optional for non-applied scenarios or test purposes
- An IDE such as Visual Studio—optional

## Adding `CestrumCore`to a Swift (Package) Project
Add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/Wadye17/CestrumCore", branch: "main")
```

# Example Usage
Whilst `CestrumCore` implements the core of the approach, it is not made to be used on application-level as it requires some experience with the
Swift programming language. For an actual, easier use, please refer to [CestrumCLI](https://github.com/Wadye17/cestrum-cli).

## Import the framework
```swift
import Foundation
import CestrumCore
```

## Declaring and modellig deployments and configurations
```swift
// Declare deployments
let persistence = Deployment("persistence")
let backend = Deployment("backend")
let frontend = Deployment("frontend")
let notificationService = Deployment("notification")
let authService = Deployment("auth")

// Create (model) a configuration
let graph = try DependencyGraph(name: "my_config", deployments: persistence, frontend,
    backend, notificationService, authService) {
    [frontend, notificationService] --> backend // custom many-to-one operator
    backend --> [persistence, authService] // custom one-to-many operator
    authService --> persistence // one-to-one operator
}
```

## Programmatically create an abstract specification
```swift
// Declare an abstract specification — programmatically...
let specification: AbstractFormula = [
    .replace(oldDeploymentName: "backend", newDeployment: Deployment("new-backend")),
    .replace(oldDeploymentName: "auth", newDeployment: Deployment("new-auth"))
]
```

## Interpret an abstract specification from a CESR script
```swift
// Interpret a specification written in CESR
let script =
"""
configuration "doc";
replace auth with new-auth "path/to/new-auth.yaml";
replace backend with new-backend "path/to/new-backend.yaml";
"""

// capture the result of the interpretation (either a success, or a list of CESR errors)
let result = CESRInterpreter.interpret(code: code)
        
guard case .success(let interpretedContent) = result else {
  print("Interpretation failed")
  return
}

// Capture the result on success
let (graphName, specification) = interpretedContent
```
Interpretation errors are captured by the `CESRInterpreter` in the `error` result in the form of an array (lines and messages).

## Generating and running concrete plans
```swift
// Construct target graph from the source graph by applying the specification
let targetGraph = try specification.createTargetGraph(from: graph)

// Generate the parallelisable plan
let workflow = ConcreteWorkflow(initialGraph: graph, targetGraph: targetGraph)

// Run the parallelisable plan (requires macOS 13 or later)
try workflow.apply(on graph, stderr: FileHandle.stderr)
```

> [!Note]
> The execution of the parallelisable plan is only supported on macOS 13.0 or later. Full support available soon.

# Main Concepts and Their Implementations
| Concept | Implementation | Data Type |
| --- | --- | --- |
| Deployment | `Deployment` | Class
| Configuration | `DependencyGraph` | Class
| CESR Interpreter | `CESRInterpreter` | Struct
| Abstract Operation | `AbstactOperation` | Enumeration
| Abstract Specification | `AbstractFormula` | Struct
| Concete Operation | `ConcreteOperation` | Enumeration
| Sequential Concrete Plan | `ConcretePlan` | Class
| Parallelisable Concrete Plan | `ConcreteWorkflow` | Class
| Delta | Implicit | -

> [!Important]
> Due to technical reasons, some features such as interpreter preferences (verification of YAML manifests, etc.) are not yet available and their public release has been deferred to a later date.
