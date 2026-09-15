//
//  SettingView.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

// MARK: - SettingTab

enum SettingTab: Int {
    case general
    case service
    case shortcut
}

// MARK: - SettingView

struct SettingView: View {
    // MARK: Internal

    var body: some View {
        TabView(selection: $selection) {
            GeneralTab()
                .tabItem { Label("setting_general", systemImage: "gear") }
                .tag(SettingTab.general)

            ServiceTab()
                .tabItem { Label("service", systemSymbol: .characterBubble) }
                .tag(SettingTab.service)

            ShortcutTab()
                .tabItem { Label("shortcut", systemImage: "command.square") }
                .tag(SettingTab.shortcut)
        }
        .background(
            WindowAccessor(window: $window.didSet(execute: { _ in
                // reset frame when first launch
                resizeWindowFrame()
            }))
        )
        .onChange(of: selection) { _ in
            resizeWindowFrame()
        }
    }

    func resizeWindowFrame() {
        guard let window else { return }

        // Disable zoom button, refer: https://stackoverflow.com/a/66039864/8378840
        window.standardWindowButton(.zoomButton)?.isEnabled = false

        // Keep the settings page Windows all the same width to avoid strange animations.
        let newSize = CGSize(width: 820, height: 560)

        let originalFrame = window.frame
        let newY = originalFrame.origin.y + originalFrame.size.height - newSize.height
        let newRect = NSRect(origin: CGPoint(x: originalFrame.origin.x, y: newY), size: newSize)

        window.setFrame(newRect, display: true, animate: false)
        // macOS 27: keep the sidebar below the title bar by removing the
        // `.fullSizeContentView` style SwiftUI keeps after resize. Older macOS
        // versions are unaffected.
        // Refer: https://github.com/tisfeng/Easydict/pull/1258#issuecomment-5186918247
        if #available(macOS 27.0, *) {
            window.styleMask.remove(.fullSizeContentView)
        }
        window.styleMask.remove(.resizable)
    }

    // MARK: Private

    @State private var selection = SettingTab.general
    @State private var window: NSWindow?
}

#Preview {
    SettingView()
}
