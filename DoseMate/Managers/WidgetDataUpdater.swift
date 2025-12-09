//
//  WidgetDataUpdater.swift
//  DoseMate
//
//  Created by bbdyno on 12/09/25.
//

import Foundation
import SwiftData
import SwiftUI
import WidgetKit

/// 위젯 데이터 업데이트 관리자
@MainActor
final class WidgetDataUpdater {
    // MARK: - Singleton

    static let shared = WidgetDataUpdater()

    // MARK: - App Group Identifier

    private let appGroupIdentifier = "group.com.bbdyno.app.doseMate"

    // MARK: - UserDefaults

    private var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 위젯 데이터 업데이트 (ModelContext 전달받음)
    func updateWidgetData(context: ModelContext? = nil) {
        print("[Widget] 위젯 데이터 업데이트 시작")

        // 전달받은 컨텍스트 또는 DataManager의 컨텍스트 사용
        let modelContext = context ?? DataManager.shared.context

        // 오늘의 로그 가져오기
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let predicate = #Predicate<MedicationLog> { log in
            log.scheduledTime >= today && log.scheduledTime < tomorrow
        }

        let descriptor = FetchDescriptor<MedicationLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.scheduledTime)]
        )

        let todayLogs: [MedicationLog]
        do {
            todayLogs = try modelContext.fetch(descriptor)
            print("[Widget] 오늘의 로그 \(todayLogs.count)개 로드")
        } catch {
            print("[Widget] ❌ 로그 로드 실패: \(error)")
            todayLogs = []
        }

        // 위젯에 표시할 약물 로그 (최대 3개)
        let medications = todayLogs.prefix(3).compactMap { log -> WidgetMedicationItem? in
            guard let medication = log.medication else { return nil }

            return WidgetMedicationItem(
                id: log.id,
                name: medication.name,
                dosage: medication.dosage.isEmpty ? medication.strength : medication.dosage,
                scheduledTime: log.scheduledTime,
                status: log.status,
                statusColorHex: log.statusColor.hexString
            )
        }
        print("[Widget] 위젯용 약물 \(medications.count)개 준비")

        // 준수율 계산
        let adherenceRate: Double
        if todayLogs.isEmpty {
            adherenceRate = 0.0
        } else {
            let completedLogs = todayLogs.filter { $0.logStatus == .taken || $0.logStatus == .delayed }
            adherenceRate = Double(completedLogs.count) / Double(todayLogs.count)
        }
        print("[Widget] 준수율: \(Int(adherenceRate * 100))%")

        // 다음 복약 찾기
        let nextDose: WidgetMedicationItem? = {
            let now = Date()
            let upcomingLog = todayLogs.first { log in
                log.logStatus == .pending && log.scheduledTime > now
            }

            guard let log = upcomingLog, let medication = log.medication else {
                return nil
            }

            return WidgetMedicationItem(
                id: log.id,
                name: medication.name,
                dosage: medication.dosage.isEmpty ? medication.strength : medication.dosage,
                scheduledTime: log.scheduledTime,
                status: log.status,
                statusColorHex: log.statusColor.hexString
            )
        }()

        if let next = nextDose {
            print("[Widget] 다음 복약: \(next.name) at \(next.scheduledTime)")
        } else {
            print("[Widget] 다음 복약 없음")
        }

        // 위젯 데이터 생성
        let widgetData = WidgetData(
            medications: Array(medications),
            adherenceRate: adherenceRate,
            nextDose: nextDose,
            updatedAt: Date()
        )

        // 저장
        widgetData.save()

        // 위젯 리로드
        reloadWidgets()
    }

    /// 위젯 리로드
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        print("[Widget] 위젯 리로드 완료")
    }
}

// MARK: - Widget Data Models (메인 앱에서 사용)

/// 위젯 데이터 구조체
struct WidgetData: Codable {
    let medications: [WidgetMedicationItem]
    let adherenceRate: Double
    let nextDose: WidgetMedicationItem?
    let updatedAt: Date

    /// 메인 앱에서 저장하는 메서드
    func save() {
        let appGroupIdentifier = "group.com.bbdyno.app.doseMate"
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
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
}

// MARK: - Color Extension

extension Color {
    var hexString: String {
        guard let components = UIColor(self).cgColor.components else { return "#808080" }

        let r = Int((components.count > 0 ? components[0] : 0) * 255.0)
        let g = Int((components.count > 1 ? components[1] : 0) * 255.0)
        let b = Int((components.count > 2 ? components[2] : 0) * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
