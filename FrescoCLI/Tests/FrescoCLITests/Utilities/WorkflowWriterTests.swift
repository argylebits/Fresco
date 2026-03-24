import Foundation
import Testing

@testable import FrescoCLI

@Suite("WorkflowWriter")
struct WorkflowWriterTests {
    private let writer = WorkflowWriter()

    @Test("cronExpression for daily schedule")
    func cronExpressionDaily() {
        #expect(writer.cronExpression(schedule: "daily", hour: 8) == "0 8 * * *")
    }

    @Test("cronExpression for weekly schedule")
    func cronExpressionWeekly() {
        #expect(writer.cronExpression(schedule: "weekly", hour: 12) == "0 12 * * 1")
    }

    @Test("cronExpression for monthly schedule")
    func cronExpressionMonthly() {
        #expect(writer.cronExpression(schedule: "monthly", hour: 0) == "0 0 1 * *")
    }

    @Test("cronExpression for quarterly schedule")
    func cronExpressionQuarterly() {
        #expect(writer.cronExpression(schedule: "quarterly", hour: 6) == "0 6 1 1,4,7,10 *")
    }

    @Test("cronExpression for annual schedule")
    func cronExpressionAnnual() {
        #expect(writer.cronExpression(schedule: "annual", hour: 23) == "0 23 1 1 *")
    }

    @Test("writeWorkflow creates file with correct cron expression")
    func writeWorkflowCreatesFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let workflowPath = tempDir.appendingPathComponent("fresco.yml").path

        try writer.writeWorkflow(to: workflowPath, schedule: "weekly", scheduleHour: 14)

        let content = try String(contentsOfFile: workflowPath, encoding: .utf8)
        #expect(content.contains("cron: '0 14 * * 1'"))
        #expect(content.contains("name: Fresco Image Generation"))
    }
}
