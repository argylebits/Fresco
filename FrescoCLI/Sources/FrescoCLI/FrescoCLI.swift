import ArgumentParser

@main
struct Fresco: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fresco",
        abstract: "AI image generation CLI",
        version: "Fresco v\(appVersion)",
        subcommands: [GenerateCommand.self]
    )
}
