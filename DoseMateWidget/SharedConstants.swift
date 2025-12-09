//
//  SharedConstants.swift
//  DoseMate
//
//  Created by bbdyno on 12/09/25.
//

import Foundation

/// 메인 앱과 위젯 간 공유되는 상수
enum SharedConstants {
    /// App Group Identifier
    static let appGroupIdentifier = "group.com.bbdyno.app.doseMate"

    /// UserDefaults Suite
    static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    /// 공유 컨테이너 URL
    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
}
