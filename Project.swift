import ProjectDescription

let project = Project(
    name: "PillMate",
    targets: [
        .target(
            name: "PillMate",
            destinations: .iOS,
            product: .app,
            bundleId: "com.bbdyno.app.pillMate",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDevelopmentRegion": "en",
                    "CFBundleLocalizations": ["en", "ko", "id", "zh-Hans", "ja"],
                    "CFBundleDisplayName": "복약 관리",
                    "ITSAppUsesNonExemptEncryption": false,
                    "NSCameraUsageDescription": "약물 사진을 촬영하여 등록할 수 있습니다.",
                    "NSFaceIDUsageDescription": "Face ID를 사용하여 앱에 빠르게 접근할 수 있습니다.",
                    "NSHealthShareUsageDescription": "건강 데이터를 읽어 복약 관리와 건강 지표 추적에 활용합니다.",
                    "NSHealthUpdateUsageDescription": "건강 데이터에 복약 기록과 건강 지표를 저장합니다.",
                    "NSPhotoLibraryUsageDescription": "약물 사진을 갤러리에서 선택할 수 있습니다.",
                    "NSUserNotificationsUsageDescription": "복약 시간에 알림을 보내 약 복용을 잊지 않도록 도와드립니다.",
                    "UIApplicationSceneManifest": [
                        "UIApplicationSupportsMultipleScenes": true
                    ],
                    "UILaunchScreen": [:],
                    "UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight"
                    ],
                    "UISupportedInterfaceOrientations~ipad": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationPortraitUpsideDown",
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight"
                    ],
                    "UIBackgroundModes": [
                        "fetch",
                        "processing",
                        "remote-notification"
                    ],
                    "NSAppTransportSecurity": [
                        "NSAllowsArbitraryLoads": false
                    ]
                ]
            ),
            sources: ["PillMate/**"],
            resources: ["PillMate/**/*.{xcassets,strings,storyboard,xib}"],
            scripts: [
                .pre(
                    path: .relativeToRoot("scripts/swiftgen.sh"),
                    name: "SwiftGen",
                    basedOnDependencyAnalysis: false
                )
            ],
            dependencies: [
                .target(name: "PillMateWidget"),
                .external(name: "SDWebImage"),
                .external(name: "SDWebImageSwiftUI")
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Manual",
                    "CODE_SIGN_IDENTITY": "iPhone Developer: Taein Kim",
                    "DEVELOPMENT_TEAM": "4U62JZ6987",
                    "PROVISIONING_PROFILE_SPECIFIER": "PillMate App Provisioning"
                ]
            )
        ),
        .target(
            name: "PillMateWidget",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.bbdyno.app.pillMate.widget",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(
                with: [
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                    ]
                ]
            ),
            sources: ["PillMateWidget/**"],
            resources: ["PillMateWidget/**/*.xcassets"],
            dependencies: [],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Manual",
                    "CODE_SIGN_IDENTITY": "iPhone Developer: Taein Kim",
                    "DEVELOPMENT_TEAM": "4U62JZ6987",
                    "PROVISIONING_PROFILE_SPECIFIER": "PillMate WidgetExtension Provisioning"
                ]
            )
        ),
        .target(
            name: "PillMateTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.bbdyno.app.pillMate.tests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["PillMateTests/**"],
            dependencies: [
                .target(name: "PillMate")
            ]
        ),
        .target(
            name: "PillMateUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.bbdyno.app.pillMate.uitests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["PillMateUITests/**"],
            dependencies: [
                .target(name: "PillMate")
            ]
        )
    ]
)
