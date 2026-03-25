import Testing
@testable import FrescoCLI

@Suite("FrescoCLI")
struct FrescoCLITests {
    @Test func subcommands_doesNotIncludeInit() {
        let names = Fresco.configuration.subcommands.map { $0.configuration.commandName }
        #expect(!names.contains("init"))
    }
}
