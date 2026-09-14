//
//  AppleService.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/9.
//  Copyright © 2024 izual. All rights reserved.
//

import AVFoundation
import Foundation
import NaturalLanguage
import Vision

// MARK: - AppleService

@objc(EZAppleService)
public class AppleService: QueryService {
    // MARK: Public

    public override func serviceType() -> ServiceType {
        .apple
    }

    public override func name() -> String {
        NSLocalizedString("apple_translate", comment: "")
    }

    public override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .none
    }

    /// Supported languages dictionary
    @objc
    public override func supportLanguagesDictionary() -> MMOrderedDictionary {
        languageMapper.supportedLanguages.toMMOrderedDictionary()
    }

    /// Detect language using Apple's language detection.
    @nonobjc
    public override func detectText(_ text: String) async throws -> Language {
        let language = detectTextSync(text)
        return language
    }

    /// Detect language for Objective-C callers without spinning up a Task.
    @objc
    public override func detectText(
        _ text: String,
        completionHandler: @escaping (Language, Error?) -> ()
    ) {
        completionHandler(detectTextSync(text), nil)
    }

    /// Perform OCR using Apple's Vision-based engine.
    public override func ocr(
        _ image: NSImage,
        from: Language,
        to: Language
    ) async throws
        -> EZOCRResult? {
        _ = to
        return try await withCheckedThrowingContinuation { continuation in
            ocrEnginee.recognizeText(
                image: image,
                language: from
            ) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }

    @objc
    public func detectTextSync(_ text: String) -> Language {
        languageDetector.detectLanguage(text: text)
    }

    /// Play text audio using system speech synthesizer
    @objc
    public func playTextAudio(_ text: String, textLanguage: Language) -> NSSpeechSynthesizer? {
        speechService.playAudio(text: text, language: textLanguage) { _ in }
    }

    /// Convert NLLanguage to Language enum
    @objc
    public func languageEnum(fromAppleLanguage appleLanguage: NLLanguage) -> Language {
        languageMapper.languageEnum(from: appleLanguage)
    }

    // MARK: Internal

    @objc static let shared = AppleService()

    // MARK: Private

    private let ocrEnginee = AppleOCREngine()
    private let languageMapper = AppleLanguageMapper.shared
    private let languageDetector = AppleLanguageDetector(enableDebugLog: true)
    private let speechService = AppleSpeechService()
}

extension NLLanguage {
    var localeLanguage: Locale.Language {
        .init(identifier: rawValue)
    }
}

// MARK: - Locale.Language + @retroactive CustomStringConvertible

extension Locale.Language: @retroactive CustomStringConvertible {
    public var description: String {
        let currentLocal = Locale.current // Locale.current.identifier = "zh_CN"
        let locale = Locale(identifier: maximalIdentifier)

        if let languageCode = languageCode {
            let identifier = languageCode.identifier
            let localizedName = currentLocal.localizedString(forIdentifier: identifier) ?? ""
            let region =
                currentLocal.localizedString(forRegionCode: locale.region?.identifier ?? "") ?? ""
            return
                "\(identifier) \(minimalIdentifier) \(maximalIdentifier) \(localizedName) (\(region))"
        }
        return "\(languageCode?.identifier ?? "nil") maximalIdentifier: \(maximalIdentifier)"
    }
}
