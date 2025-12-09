//
//  DoseMateSchemaHistory.swift
//  DoseMate
//
//  Created by bbdyno on 12/09/25.
//

import Foundation
import SwiftData

/// DoseMate 스키마 마이그레이션 플랜
///
/// SwiftData는 이 플랜을 사용하여 자동으로 스키마를 마이그레이션합니다.
/// - Lightweight migration: 필드 추가/삭제, 타입 변경 등 자동 처리
/// - Custom migration: 복잡한 데이터 변환이 필요한 경우 직접 구현
enum DoseMateSchemaHistory: SchemaMigrationPlan {
    /// 모든 스키마 버전 (순서대로)
    static var schemas: [any VersionedSchema.Type] {
        [
            DoseMateSchemaV1.self
            // 향후 버전 추가 시:
            // DoseMateSchemaV2.self,
            // DoseMateSchemaV3.self
        ]
    }

    /// 버전 간 마이그레이션 단계
    static var stages: [MigrationStage] {
        [
            // 향후 V1 -> V2 마이그레이션 단계 추가 예시:
            // migrateV1toV2
        ]
    }

    // MARK: - Migration Stages

    // 향후 마이그레이션 단계 추가 예시:
    //
    // static let migrateV1toV2 = MigrationStage.custom(
    //     fromVersion: DoseMateSchemaV1.self,
    //     toVersion: DoseMateSchemaV2.self,
    //     willMigrate: { context in
    //         print("스키마 마이그레이션 시작: V1 -> V2")
    //     },
    //     didMigrate: { context in
    //         print("스키마 마이그레이션 완료: V1 -> V2")
    //
    //         // 커스텀 데이터 변환 작업
    //         // 예: 새로운 필드에 기본값 설정
    //         do {
    //             let medications = try context.fetch(FetchDescriptor<Medication>())
    //             for medication in medications {
    //                 // 새 필드 초기화
    //             }
    //             try context.save()
    //         } catch {
    //             print("마이그레이션 중 오류: \(error)")
    //         }
    //     }
    // )
}
