import ArgumentParser

struct RemoteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remote",
        abstract: "Manage remote storage objects",
        subcommands: [RemoteCopyCommand.self]
    )
}
