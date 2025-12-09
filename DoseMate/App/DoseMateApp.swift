//
//  DoseMateApp.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import SwiftData
import UserNotifications

/// 메인 앱
@main
struct DoseMateApp: App {
    // MARK: - Properties
    
    /// 앱 델리게이트
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /// 외관 모드
    @AppStorage(AppConstants.UserDefaultsKeys.appearanceMode) private var appearanceMode = "system"
    
    /// SwiftData 모델 컨테이너
    let modelContainer: ModelContainer

    /// Scene Phase
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Initialization
    
    init() {
        // 모델 컨테이너 설정
        let schema = Schema([
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self,
            HealthMetric.self,
            Appointment.self,
            Caregiver.self,
            Patient.self
        ])
        
        // iCloud 동기화 설정 (프리미엄 + 사용자 설정에 따라)
        let shouldEnableCloudKit = Self.shouldEnableCloudSync()

        // App Group을 사용하여 위젯과 데이터 공유
        let appGroupIdentifier = "group.com.bbdyno.app.doseMate"
        guard let groupContainerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            fatalError("App Group 컨테이너를 찾을 수 없습니다. Entitlements를 확인하세요.")
        }

        let modelConfiguration: ModelConfiguration
        if shouldEnableCloudKit {
            // iCloud 동기화 활성화
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: groupContainerURL.appendingPathComponent("DoseMate.sqlite"),
                allowsSave: true,
                cloudKitDatabase: .automatic
            )
            print("iCloud 동기화 활성화됨")
        } else {
            // 로컬 전용
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: groupContainerURL.appendingPathComponent("DoseMate.sqlite"),
                allowsSave: true,
                cloudKitDatabase: .none
            )
            print("로컬 전용 모드")
        }

        print("SwiftData 컨테이너 초기화: \(groupContainerURL.path)")
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // 외관 설정
        configureAppearance()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
                .onAppear {
                    setupNotifications()
                    updateWidgetData()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        updateWidgetData()
                    }
                }
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Computed Properties
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    // MARK: - Static Methods
    
    /// iCloud 동기화 활성화 여부 결정
    /// - 프리미엄 사용자이고, iCloud 동기화 설정이 켜져 있을 때만 활성화
    private static func shouldEnableCloudSync() -> Bool {
        // 1. 프리미엄 상태 확인 (캐시된 값 사용)
        let isPremiumCached = UserDefaults.standard.bool(forKey: "isPremiumCached")
        
        // 2. 사용자의 iCloud 동기화 설정 확인
        let iCloudSyncEnabled = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.iCloudSyncEnabled)
        
        // 3. iCloud 계정 가용성 확인
        let isICloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        
        #if DEBUG
        print("프리미엄 (캐시): \(isPremiumCached)")
        print("iCloud 설정: \(iCloudSyncEnabled)")
        print("iCloud 가용: \(isICloudAvailable)")
        #endif
        
        return isPremiumCached && iCloudSyncEnabled && isICloudAvailable
    }
    
    /// 현재 iCloud 동기화 상태 확인
    static var isCloudSyncEnabled: Bool {
        shouldEnableCloudSync()
    }
    
    // MARK: - Methods
    
    /// 외관 설정
    private func configureAppearance() {
        // 네비게이션 바 외관
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // 탭 바 외관
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    /// 알림 설정
    private func setupNotifications() {
        Task {
            do {
                try await NotificationManager.shared.requestAuthorization()
            } catch {
                print("알림 권한 요청 실패: \(error)")
            }
        }
    }

    /// 위젯 데이터 업데이트
    private func updateWidgetData() {
        Task { @MainActor in
            // DataManager의 context 사용 (앱 시작 시)
            WidgetDataUpdater.shared.updateWidgetData(context: modelContainer.mainContext)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 알림 델리게이트 설정
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // 원격 알림 등록 처리
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("원격 알림 등록 실패: \(error)")
    }
}
