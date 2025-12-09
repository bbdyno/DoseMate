//
//  MigrationManager.swift
//  DoseMate
//
//  Created by bbdyno on 12/09/25.
//

import Foundation
import SwiftData

@MainActor
final class MigrationManager {
    static let shared = MigrationManager()

    // MARK: - Properties

    private let appGroupIdentifier = "group.com.bbdyno.app.doseMate"

    // MARK: - Initialization

    private init() {}

    // MARK: - Migration Status

    /// 현재 스키마 버전 확인
    func currentSchemaVersion() -> Schema.Version? {
        return DoseMateSchemaV1.versionIdentifier
    }

    /// 마이그레이션 필요 여부 확인
    func needsMigration() -> Bool {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return false
        }

        let storeURL = containerURL.appendingPathComponent("DoseMate.sqlite")
        return FileManager.default.fileExists(atPath: storeURL.path)
    }

    // MARK: - Backup & Recovery

    /// 데이터베이스 백업 생성
    func createBackup() -> Bool {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            print("App Group 컨테이너를 찾을 수 없습니다.")
            return false
        }

        let storeURL = containerURL.appendingPathComponent("DoseMate.sqlite")
        let backupURL = containerURL.appendingPathComponent("DoseMate_backup_\(Date().timeIntervalSince1970).sqlite")

        do {
            if FileManager.default.fileExists(atPath: storeURL.path) {
                try FileManager.default.copyItem(at: storeURL, to: backupURL)
                print("데이터베이스 백업 성공: \(backupURL.lastPathComponent)")
                return true
            } else {
                print("백업할 데이터베이스 파일이 없습니다.")
                return false
            }
        } catch {
            print("데이터베이스 백업 실패: \(error)")
            return false
        }
    }

    /// 가장 최근 백업에서 복원
    func restoreFromBackup() -> Bool {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            print("App Group 컨테이너를 찾을 수 없습니다.")
            return false
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: containerURL,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            // 백업 파일 찾기
            let backupFiles = contents.filter { $0.lastPathComponent.hasPrefix("DoseMate_backup_") }

            guard let latestBackup = backupFiles.sorted(by: { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }).first else {
                print("복원할 백업 파일이 없습니다.")
                return false
            }

            let storeURL = containerURL.appendingPathComponent("DoseMate.sqlite")

            // 현재 파일 삭제 (있는 경우)
            if FileManager.default.fileExists(atPath: storeURL.path) {
                try FileManager.default.removeItem(at: storeURL)
            }

            // 백업에서 복원
            try FileManager.default.copyItem(at: latestBackup, to: storeURL)
            print("백업에서 복원 성공: \(latestBackup.lastPathComponent)")
            return true
        } catch {
            print("백업 복원 실패: \(error)")
            return false
        }
    }

    /// 모든 백업 파일 삭제
    func cleanupOldBackups(keepRecent: Int = 3) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: containerURL,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            // 백업 파일 찾기
            let backupFiles = contents.filter { $0.lastPathComponent.hasPrefix("DoseMate_backup_") }

            // 최신 파일 제외하고 삭제
            let sortedBackups = backupFiles.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }

            for (index, backup) in sortedBackups.enumerated() where index >= keepRecent {
                try FileManager.default.removeItem(at: backup)
                print("오래된 백업 삭제: \(backup.lastPathComponent)")
            }
        } catch {
            print("백업 정리 실패: \(error)")
        }
    }

    // MARK: - iCloud Conflict Resolution

    /// iCloud 동기화 충돌 확인
    func checkForCloudConflicts() -> Bool {
        // iCloud 충돌은 NSPersistentCloudKitContainer가 자동으로 처리
        // 여기서는 로깅만 수행
        print("iCloud 충돌 확인 중...")
        return false
    }

    /// iCloud 동기화 상태 확인
    func checkCloudSyncStatus() {
        if FileManager.default.ubiquityIdentityToken != nil {
            print("iCloud 계정 로그인됨")
        } else {
            print("iCloud 계정 로그인되지 않음")
        }
    }
}
