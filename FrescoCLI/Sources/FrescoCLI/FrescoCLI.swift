import ArgumentParser

@main
struct FrescoCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A Swift command-line tool."
    )

    func run() throws {
        print("Hello from FrescoCLI!")
    }
}