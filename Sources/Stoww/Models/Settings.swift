import Foundation
import SwiftUI

enum RetentionPeriod: Int, CaseIterable, Identifiable {
    case oneDay = 1
    case threeDays = 3
    case oneWeek = 7
    case twoWeeks = 14
    case oneMonth = 30
    case never = 0
    
    var id: Int { self.rawValue }
    
    var label: String {
        switch self {
        case .oneDay: return "1 day"
        case .threeDays: return "3 days"
        case .oneWeek: return "1 week"
        case .twoWeeks: return "2 weeks"
        case .oneMonth: return "1 month"
        case .never: return "Never"
        }
    }
    
    func expirationDate(from date: Date = Date()) -> Date? {
        if self == .never { return nil }
        return Calendar.current.date(byAdding: .day, value: self.rawValue, to: date)
    }
}

class AppSettings: ObservableObject {
    @AppStorage("defaultRetention") var defaultRetentionRawValue: Int = RetentionPeriod.oneWeek.rawValue
    @AppStorage("showItemCount") var showItemCount: Bool = true
    
    // Freemium State
    @AppStorage("isPro") var isPro: Bool = false
    @AppStorage("licenseKey") var licenseKey: String = ""
    @AppStorage("instanceID") var instanceID: String = ""
    
    var defaultRetention: RetentionPeriod {
        if !isPro { return .oneDay }
        return RetentionPeriod(rawValue: defaultRetentionRawValue) ?? .oneDay
    }
}
