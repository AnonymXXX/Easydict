//
//  GeneralTab.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import LaunchAtLogin
import SwiftUI

// MARK: - GeneralTab

struct GeneralTab: View {
    // MARK: Internal

    var body: some View {
        Form {
            Section {
                FirstAndSecondLanguageSettingView()
            } header: {
                Text("setting.general.query_language.header")
            }

            Section {
                Toggle("clear_input_when_translating", isOn: $clearInput)
                Toggle("auto_query_ocr_text", isOn: $autoQueryOCRText)
                Toggle("auto_copy_ocr_text", isOn: $autoCopyOCRText)
            } header: {
                Text("setting.general.input.header")
            }

            Section {
                LaunchAtLogin.Toggle {
                    Text("launch_at_startup")
                }
                .onChange(of: LaunchAtLogin.isEnabled) { newValue in
                    logSettings(["launch_at_startup": newValue])
                }
            } header: {
                Text("setting.general.app_setting.header")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Private

    @Default(.clearQueryWhenInputTranslate) private var clearInput
    @Default(.autoQueryOCRText) private var autoQueryOCRText
    @Default(.autoCopyOCRText) private var autoCopyOCRText

    private func logSettings(_ parameters: [String: Any]) {
        AnalyticsService.logEvent(withName: "settings", parameters: parameters)
    }
}

#Preview {
    GeneralTab()
}

// MARK: - FirstAndSecondLanguageSettingView

private struct FirstAndSecondLanguageSettingView: View {
    // MARK: Internal

    var body: some View {
        Group {
            Picker("setting.general.language.first_language", selection: $firstLanguage) {
                ForEach(Language.allAvailableOptions, id: \.rawValue) { option in
                    Text(verbatim: "\(option.flagEmoji) \(option.localizedName)")
                        .tag(option)
                }
            }
            Picker("setting.general.language.second_language", selection: $secondLanguage) {
                ForEach(Language.allAvailableOptions, id: \.rawValue) { option in
                    Text(verbatim: "\(option.flagEmoji) \(option.localizedName)")
                        .tag(option)
                }
            }
        }
        .onChange(of: firstLanguage) { [firstLanguage] newValue in
            let oldValue = firstLanguage
            if newValue == secondLanguage {
                secondLanguage = oldValue
                languageDuplicatedAlert = .init(
                    duplicatedLanguage: newValue, setField: .second, setLanguage: oldValue
                )
            }
        }
        .onChange(of: secondLanguage) { [secondLanguage] newValue in
            let oldValue = secondLanguage
            if newValue == firstLanguage {
                firstLanguage = oldValue
                languageDuplicatedAlert = .init(
                    duplicatedLanguage: newValue, setField: .first, setLanguage: oldValue
                )
            }
        }
        .alert(
            "setting.general.language.duplicated_alert.title",
            isPresented: showLanguageDuplicatedAlert,
            presenting: languageDuplicatedAlert
        ) { _ in
        } message: { alert in
            Text(alert.description)
        }
    }

    // MARK: Private

    private struct LanguageDuplicateAlert: CustomStringConvertible {
        enum Field: CustomLocalizedStringResourceConvertible {
            case first
            case second

            // MARK: Internal

            var localizedStringResource: LocalizedStringResource {
                switch self {
                case .first:
                    "setting.general.language.duplicated_alert.field.first"
                case .second:
                    "setting.general.language.duplicated_alert.field.second"
                }
            }
        }

        let duplicatedLanguage: Language

        let setField: Field

        let setLanguage: Language

        var description: String {
            // First language should not be same as second language. (\(duplicatedLanguage))
            // \(setField) is replaced with \(setLanguage).
            String(
                localized:
                "setting.general.language.duplicated_alert \(duplicatedLanguage.localizedName)\(String(localized: setField.localizedStringResource))\(setLanguage.localizedName)"
            )
        }
    }

    @State private var languageDuplicatedAlert: LanguageDuplicateAlert?

    @Default(.firstLanguage) private var firstLanguage
    @Default(.secondLanguage) private var secondLanguage

    private var showLanguageDuplicatedAlert: Binding<Bool> {
        .init {
            languageDuplicatedAlert != nil
        } set: { newValue in
            if !newValue {
                languageDuplicatedAlert = nil
            }
        }
    }
}
