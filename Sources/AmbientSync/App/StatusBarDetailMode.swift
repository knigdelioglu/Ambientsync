import Foundation

enum StatusBarDetailMode: String, CaseIterable, Identifiable {
    case smart
    case brightness
    case sleepCountdown
    case off

    var id: String { rawValue }

    var label: String {
        switch self {
        case .smart: return "Akıllı"
        case .brightness: return "Parlaklık"
        case .sleepCountdown: return "Uyku Geri Sayımı"
        case .off: return "Sadece İkon"
        }
    }

    var description: String {
        switch self {
        case .smart: return "Geçici süre varsa geri sayımı, yoksa parlaklığı gösterir."
        case .brightness: return "İkonun yanında monitör parlaklığı gösterilir."
        case .sleepCountdown: return "Quick panelden seçilen geçici süre varsa geri sayımı gösterir."
        case .off: return "Sadece ikon görünür."
        }
    }
}
