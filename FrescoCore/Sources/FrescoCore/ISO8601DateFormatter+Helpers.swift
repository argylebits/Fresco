import Foundation

extension ISO8601DateFormatter {
    public static func dateOnlyString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    public static func archiveKeyString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate, .withTime, .withColonSeparatorInTime]
        formatter.timeZone = TimeZone(identifier: "UTC")
        // "2025-01-01T00:00:00" → "2025-01-01-000000"
        return formatter.string(from: date)
            .replacingOccurrences(of: "T", with: "-")
            .replacingOccurrences(of: ":", with: "")
    }
}
