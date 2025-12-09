//
//  WidgetDataManager.swift
//  DoseMateWidget
//
//  Created by bbdyno on 12/09/25.
//

import Foundation
import SwiftUI

/// 위젯용 데이터 매니저
final class WidgetDataManager {
    // MARK: - Singleton

    static let shared = WidgetDataManager()

    // MARK: - Keys

    private enum Keys {
        static let widgetData = "widgetMedicationData"
        static let lastUpdate = "widgetLastUpdate"
    }

    // MARK: - Properties

    private var userDefaults: UserDefaults? {
        SharedConstants.sharedUserDefaults
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 위젯 데이터 가져오기
    func getWidgetData() -> WidgetData? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: Keys.widgetData) else {
            print("[Widget] 위젯 데이터를 찾을 수 없습니다.")
            return nil
        }

        do {
            let widgetData = try JSONDecoder().decode(WidgetData.self, from: data)
            print("[Widget] 위젯 데이터 로드 성공: \(widgetData.medications.count)개 약물")
            return widgetData
        } catch {
            print("[Widget] 위젯 데이터 디코딩 실패: \(error)")
            return nil
        }
    }

    /// 마지막 업데이트 시간
    var lastUpdateTime: Date? {
        userDefaults?.object(forKey: Keys.lastUpdate) as? Date
    }
}

// MARK: - Data Models

/// 위젯 데이터 구조체
struct WidgetData: Codable {
    let medications: [WidgetMedicationItem]
    let adherenceRate: Double
    let nextDose: WidgetMedicationItem?
    let updatedAt: Date

    /// 메인 앱에서 저장하는 메서드
    func save() {
        guard let userDefaults = SharedConstants.sharedUserDefaults else {
            print("[Widget] UserDefaults를 사용할 수 없습니다.")
            return
        }

        do {
            let data = try JSONEncoder().encode(self)
            userDefaults.set(data, forKey: "widgetMedicationData")
            userDefaults.set(Date(), forKey: "widgetLastUpdate")
            userDefaults.synchronize()
            print("[Widget] 위젯 데이터 저장 완료: \(medications.count)개 약물")
        } catch {
            print("[Widget] 위젯 데이터 저장 실패: \(error)")
        }
    }
}

/// 위젯용 약물 아이템
struct WidgetMedicationItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let dosage: String
    let scheduledTime: Date
    let status: String
    let statusColorHex: String

    var statusColor: Color {
        Color(hex: statusColorHex) ?? .gray
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
