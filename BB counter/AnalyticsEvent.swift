import Foundation

/// 埋點事件清冊。所有事件集中在這裡，才不會散成一堆字串常數、也方便對照後台。
enum AnalyticsEvent {
    enum ChipEntryMethod: String {
        case denomination   // 用面額按鈕加出來的
        case keypad         // 直接打字
    }

    enum BlindEntryMethod: String {
        case preset         // 從輪播選預設級距
        case manual         // 自己輸入大盲
    }

    enum ChipChangeDirection: String {
        case win
        case loss
    }

    // 進入流程
    case appOpened
    case onboardingCompleted
    case chipsEntered(method: ChipEntryMethod, chips: Int)
    case blindsSet(method: BlindEntryMethod, bigBlind: Int)
    case dashboardShown(bbDepth: Double)

    // 主要迴圈：籌碼
    case chipChangeLogged(direction: ChipChangeDirection)
    case chipTotalEdited
    case historyOpened

    // 主要迴圈：計時器
    case timerEnabled
    case timerStarted
    case timerPaused
    case timerResumed
    case blindLevelUp(bigBlind: Int)
    case liveActivityStarted
    case liveActivityUnavailable(reason: String)
    case customStructureSaved(levelCount: Int)

    // 行動線
    case handLineOpened
    case handLineCreated
    case handLineActionAdded(street: String)
    case handLineCopied

    // 需求測試（All-in 範圍那張假門）
    case allInPromptShown
    case allInPromptTapped

    case sessionReset

    var name: String {
        switch self {
        case .appOpened: return "app_opened"
        case .onboardingCompleted: return "onboarding_completed"
        case .chipsEntered: return "chips_entered"
        case .blindsSet: return "blinds_set"
        case .dashboardShown: return "dashboard_shown"
        case .chipChangeLogged: return "chip_change_logged"
        case .chipTotalEdited: return "chip_total_edited"
        case .historyOpened: return "history_opened"
        case .timerEnabled: return "timer_enabled"
        case .timerStarted: return "timer_started"
        case .timerPaused: return "timer_paused"
        case .timerResumed: return "timer_resumed"
        case .blindLevelUp: return "blind_level_up"
        case .liveActivityStarted: return "live_activity_started"
        case .liveActivityUnavailable: return "live_activity_unavailable"
        case .customStructureSaved: return "custom_structure_saved"
        case .handLineOpened: return "hand_line_opened"
        case .handLineCreated: return "hand_line_created"
        case .handLineActionAdded: return "hand_line_action_added"
        case .handLineCopied: return "hand_line_copied"
        case .allInPromptShown: return "all_in_prompt_shown"
        case .allInPromptTapped: return "all_in_prompt_tapped"
        case .sessionReset: return "session_reset"
        }
    }

    /// 參數一律是分桶或列舉，不送原始金額——牌局數字是使用者的隱私，也不需要精確值才能看趨勢。
    var parameters: [String: String] {
        switch self {
        case let .chipsEntered(method, chips):
            return ["method": method.rawValue, "chips_bucket": Self.bucket(chips)]
        case let .blindsSet(method, bigBlind):
            return ["method": method.rawValue, "bb_bucket": Self.bucket(bigBlind)]
        case let .dashboardShown(bbDepth):
            return ["depth_bucket": Self.depthBucket(bbDepth)]
        case let .chipChangeLogged(direction):
            return ["direction": direction.rawValue]
        case let .blindLevelUp(bigBlind):
            return ["bb_bucket": Self.bucket(bigBlind)]
        case let .liveActivityUnavailable(reason):
            return ["reason": reason]
        case let .customStructureSaved(levelCount):
            return ["levels": String(levelCount)]
        case let .handLineActionAdded(street):
            return ["street": street]
        default:
            return [:]
        }
    }

    static func bucket(_ value: Int) -> String {
        switch value {
        case ..<0: return "invalid"
        case 0..<1_000: return "<1k"
        case 1_000..<10_000: return "1k-10k"
        case 10_000..<50_000: return "10k-50k"
        case 50_000..<200_000: return "50k-200k"
        default: return "200k+"
        }
    }

    static func depthBucket(_ bb: Double) -> String {
        switch bb {
        case ..<10: return "<10bb"
        case 10..<20: return "10-20bb"
        case 20..<40: return "20-40bb"
        case 40..<100: return "40-100bb"
        default: return "100bb+"
        }
    }
}
