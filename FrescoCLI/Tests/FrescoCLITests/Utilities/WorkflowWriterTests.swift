import Foundation
import FrescoCore
import Testing

@testable import FrescoCLI

@Suite("WorkflowWriter")
struct WorkflowWriterTests {
    private let writer = WorkflowWriter()

    @Test("cronExpression for daily schedule")
    func cronExpressionDaily() throws {
        #expect(try writer.cronExpression(schedule: "daily", hour: 8) == "0 8 * * *")
    }

    @Test("cronExpression for weekly schedule")
    func cronExpressionWeekly() throws {
        #expect(try writer.cronExpression(schedule: "weekly", hour: 12) == "0 12 * * 1")
    }

    @Test("cronExpression for monthly schedule")
    func cronExpressionMonthly() throws {
        #expect(try writer.cronExpression(schedule: "monthly", hour: 0) == "0 0 1 * *")
    }

    @Test("cronExpression for quarterly schedule")
    func cronExpressionQuarterly() throws {
        #expect(try writer.cronExpression(schedule: "quarterly", hour: 6) == "0 6 1 1,4,7,10 *")
    }

    @Test("cronExpression for annual schedule")
    func cronExpressionAnnual() throws {
        #expect(try writer.cronExpression(schedule: "annual", hour: 23) == "0 23 1 1 *")
    }

    @Test("cronExpression throws for invalid schedule")
    func cronExpressionInvalidSchedule() {
        #expect(throws: FrescoError.self) {
            try writer.cronExpression(schedule: "biweekly", hour: 8)
        }
    }

    @Test("cronExpression throws for negative hour")
    func cronExpressionNegativeHour() {
        #expect(throws: FrescoError.self) {
            try writer.cronExpression(schedule: "daily", hour: -1)
        }
    }

    @Test("cronExpression throws for hour above 23")
    func cronExpressionHourAbove23() {
        #expect(throws: FrescoError.self) {
            try writer.cronExpression(schedule: "daily", hour: 24)
        }
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
