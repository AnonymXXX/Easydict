//
//  MenuItemView.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import SettingsAccess
import SFSafeSymbols
import SwiftUI

// MARK: - MenuItemView

struct MenuItemView: View {
    // MARK: Internal

    var body: some View {
        // .menuBarExtraStyle为 .menu 时某些控件可能会失效，只能显示内容（按照菜单项高度、图像以 template 方式渲染）无法交互
        // 比如 Stepper、Slider 等，像基本的 Button、Text、Divider、Image 等还是能正常显示的。
        // Button 和Label的systemImage是不会渲染的
        Group {
            versionItem

            Divider()

            inputItem.keyboardShortcut(.inputTranslate)
            screenshotItem.keyboardShortcut(.snipTranslate)

            Divider()

            settingItem.keyboardShortcut(.init(","))
            quitItem.keyboardShortcut(.init("q"))
        }
    }

    // MARK: - Menu Items

    @ViewBuilder var inputItem: some View {
        menuItem(for: .inputTranslate)
    }

    // MARK: Private

    @State private var currentVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    @Environment(\.openURL) private var openURL

    private var versionString: String {
        "Easydict Lite  \(currentVersion)"
    }

    @ViewBuilder private var screenshotItem: some View {
        menuItem(for: .snipTranslate)
    }

    // MARK: - Other Items

    /// Version item
    @ViewBuilder private var versionItem: some View {
        Button(versionString) {
            guard let versionURL = URL(string: "\(EZGithubRepoEasydictURL)/releases") else {
                return
            }
            openURL(versionURL)
        }
    }

    /// Settings item
    @ViewBuilder private var settingItem: some View {
        let titleKey = LocalizedStringKey("Settings...")
        if #available(macOS 14.0, *) {
            SettingsLink {
                Text(titleKey)
            } preAction: {
                logInfo("Open App Settings")
                NSApplication.shared.activateApp()
            } postAction: {
                // nothing to do
            }
        } else {
            Button(titleKey) {
                logInfo("Open App Settings")
                NSApplication.shared.activateApp()

                // Refer https://stackoverflow.com/a/77265223/8378840
                NSApplication.shared.sendAction(
                    Selector(("showSettingsWindow:")), to: nil, from: nil
                )
            }
        }
    }

    /// Quit item
    @ViewBuilder private var quitItem: some View {
        Button("quit") {
            logInfo("Quit Application")
            NSApplication.shared.terminate(nil)
        }
    }

}

// MARK: - MenuItemView Extensions

extension MenuItemView {
    /// Create a menu item from ShortcutAction configuration
    fileprivate func menuItem(for shortcutType: ShortcutAction) -> some View {
        MenuItemBuilder(
            data: MenuItemData(
                icon: shortcutType.icon,
                titleKey: shortcutType.localizedStringKey(),
                action: shortcutType.executeAction
            )
        )
    }
}

// MARK: - MenuItemData

/// Data structure for menu items
private struct MenuItemData {
    // MARK: Lifecycle

    init(icon: SFSymbol, titleKey: String, action: @escaping () -> ()) {
        self.icon = icon
        self.titleKey = titleKey
        self.action = action
    }

    // MARK: Internal

    let icon: SFSymbol
    let titleKey: String
    let action: () -> ()
}

// MARK: - MenuItemBuilder

/// Builder for creating consistent menu items
private struct MenuItemBuilder: View {
    let data: MenuItemData

    var body: some View {
        let titleKey = data.titleKey
        Button {
            logInfo("Menu Action: \(titleKey)")
            data.action()
        } label: {
            HStack {
                Image(systemSymbol: data.icon)
                Text(LocalizedStringKey(titleKey))
            }
        }
    }
}

#Preview {
    MenuItemView()
}
