//
//  DeepSeekService.swift
//  Easydict
//
//  Created by GarethNg on 2025/2/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - DeepSeekService

/// DeepSeek translation service with provider-specific adapters for the
/// official API and OpenCode Go's OpenAI-compatible API.
@objc(EZDeepSeekService)
class DeepSeekService: StreamService {
    // MARK: Lifecycle

    required init() {
        super.init()
        migrateLegacyProviderConfigurationIfNeeded()
    }

    // MARK: Public

    public override func cancelStream() {
        currentTask?.cancel()
    }

    public override func name() -> String {
        NSLocalizedString("deepseek_translate", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .deepSeek
    }

    public override func link() -> String? {
        provider.adapter.link
    }

    public override func configurationListItems() -> Any? {
        DeepSeekConfigurationView(service: self)
    }

    // MARK: Internal

    override var defaultModels: [String] {
        provider.adapter.models
    }

    override var defaultModel: String {
        provider.adapter.defaultModel
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey]
    }

    override var defaultEndpoint: String {
        provider.adapter.endpoint
    }

    override var endpoint: String {
        provider.adapter.endpoint
    }

    override var apiKeyKey: Defaults.Key<String> {
        switch provider {
        case .deepSeekOfficial:
            officialAPIKeyKey
        case .openCodeGo:
            openCodeGoAPIKeyKey
        }
    }

    override var supportsReasoningEffort: Bool {
        provider.adapter.supportsReasoningEffort
    }

    var providerKey: Defaults.Key<String> {
        stringDefaultsKey(.provider)
    }

    var provider: DeepSeekProvider {
        if let storedProvider = DeepSeekProvider(rawValue: Defaults[providerKey]) {
            return storedProvider
        }

        return Self.providerInferred(from: Defaults[legacyEndpointKey])
    }

    override func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard let url = URL(string: endpoint), url.isValid else {
                continuation.finish(
                    throwing: QueryError(
                        type: .parameter,
                        message: "`\(serviceType().rawValue)` endpoint is invalid"
                    )
                )
                return
            }

            guard !apiKey.isEmpty else {
                continuation.finish(
                    throwing: QueryError(type: .missingSecretKey, message: "API key is empty")
                )
                return
            }

            if let currentTask, !currentTask.isCancelled {
                currentTask.cancel()
            }

            let task = Task {
                do {
                    let queryType = queryType(text: text, from: from, to: to)
                    let chatQueryParam = ChatQueryParam(
                        text: text,
                        sourceLanguage: from,
                        targetLanguage: to,
                        queryType: queryType,
                        enableSystemPrompt: true
                    )
                    let request = try makeChatRequest(
                        url: url,
                        messages: chatMessageDicts(chatQueryParam)
                    )

                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    try await validateHTTPResponse(response, responseBody: asyncBytes)
                    try await processStreamBytes(asyncBytes, continuation: continuation)
                    continuation.finish()
                } catch is CancellationError {
                    logInfo("DeepSeek task was cancelled.")
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            currentTask = task
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func selectProvider(_ provider: DeepSeekProvider) {
        Defaults[providerKey] = provider.rawValue
        applyConfiguration(for: provider)
        notifyServiceConfigurationChanged(autoQuery: true)
    }

    // MARK: Private

    private var currentTask: Task<(), Never>?

    private var officialAPIKeyKey: Defaults.Key<String> {
        stringDefaultsKey(.apiKey)
    }

    private var openCodeGoAPIKeyKey: Defaults.Key<String> {
        stringDefaultsKey(.openCodeGoAPIKey)
    }

    private var legacyEndpointKey: Defaults.Key<String> {
        stringDefaultsKey(.endpoint, defaultValue: DeepSeekOfficialAdapter.chatCompletionsEndpoint)
    }

    private static func providerInferred(from endpoint: String) -> DeepSeekProvider {
        endpoint.localizedCaseInsensitiveContains("opencode.ai/zen/go") ? .openCodeGo : .deepSeekOfficial
    }

    private func makeChatRequest(url: URL, messages: [ChatMessage]) throws -> URLRequest {
        let requestBody = try provider.adapter.makeRequestBody(
            messages: messages,
            model: model,
            temperature: temperature,
            reasoningEffort: configuredReasoningEffort
        )

        var request = URLRequest(url: url, timeoutInterval: EZNetWorkTimeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = requestBody
        return request
    }

    private func validateHTTPResponse(
        _ response: URLResponse,
        responseBody: URLSession.AsyncBytes
    ) async throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QueryError(type: .api, message: "Invalid DeepSeek response")
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let errorDetail = try await responseBodyText(from: responseBody)
            throw QueryError(
                type: .api,
                message: "HTTP \(httpResponse.statusCode)",
                errorDataMessage: errorDetail
            )
        }
    }

    private func responseBodyText(from responseBody: URLSession.AsyncBytes) async throws -> String? {
        let maximumErrorBodySize = 8_192
        var data = Data()

        for try await byte in responseBody {
            guard data.count < maximumErrorBodySize else { break }
            data.append(byte)
        }

        let detail = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return detail?.isEmpty == false ? detail : nil
    }

    private func migrateLegacyProviderConfigurationIfNeeded() {
        guard Defaults[providerKey].isEmpty else { return }

        let inferredProvider = Self.providerInferred(from: Defaults[legacyEndpointKey])
        if inferredProvider == .openCodeGo,
           Defaults[openCodeGoAPIKeyKey].isEmpty {
            Defaults[openCodeGoAPIKeyKey] = Defaults[officialAPIKeyKey]
        }

        Defaults[providerKey] = inferredProvider.rawValue
        applyConfiguration(for: inferredProvider)
    }

    private func applyConfiguration(for provider: DeepSeekProvider) {
        let adapter = provider.adapter
        Defaults[supportedModelsKey] = supportedModels(from: adapter.models)
        Defaults[validModelsKey] = adapter.models
        if !adapter.models.contains(Defaults[modelKey]) {
            Defaults[modelKey] = adapter.defaultModel
        }
    }

    private func processStreamBytes(
        _ asyncBytes: URLSession.AsyncBytes,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        var dataBuffer = Data()
        var textBuffer = ""

        for try await byte in asyncBytes {
            try Task.checkCancellation()
            dataBuffer.append(byte)

            guard byte == 0x0A else {
                continue
            }

            if let text = String(data: dataBuffer, encoding: .utf8) {
                textBuffer.append(text)
                dataBuffer.removeAll()
                processCompleteEvents(from: &textBuffer, continuation: continuation)
            }
        }

        if !dataBuffer.isEmpty, let text = String(data: dataBuffer, encoding: .utf8) {
            textBuffer.append(text)
        }
        processCompleteEvents(from: &textBuffer, continuation: continuation)
    }

    private func processCompleteEvents(
        from textBuffer: inout String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        textBuffer = textBuffer.replacingOccurrences(of: "\r\n", with: "\n")
        let eventSeparator = "\n\n"
        guard textBuffer.contains(eventSeparator) else { return }

        let parts = textBuffer.split(separator: eventSeparator, omittingEmptySubsequences: false)
        textBuffer = String(parts.last ?? "")

        for event in parts.dropLast() where !event.isEmpty {
            guard let content = parseSSEEvent(String(event)) else { continue }
            continuation.yield(content)
        }
    }

    private func parseSSEEvent(_ event: String) -> String? {
        let dataPrefix = "data:"
        let doneFlag = "[DONE]"
        var dataString = ""

        for line in event.split(separator: "\n") where line.starts(with: dataPrefix) {
            let payload = line.dropFirst(dataPrefix.count).trimmingCharacters(in: .whitespaces)
            guard payload != doneFlag else { return nil }
            dataString += payload
        }

        guard !dataString.isEmpty,
              let data = dataString.data(using: .utf8)
        else {
            return nil
        }

        guard let chunk = try? JSONDecoder().decode(DeepSeekStreamChunk.self, from: data) else {
            logError("Failed to decode DeepSeek SSE data: \(dataString)")
            return nil
        }

        return chunk.choices.first?.delta.content
    }
}

// MARK: - DeepSeekProvider

enum DeepSeekProvider: String, CaseIterable, Equatable {
    case deepSeekOfficial = "deepseek_official"
    case openCodeGo = "opencode_go"

    // MARK: Internal

    var title: LocalizedStringKey {
        switch self {
        case .deepSeekOfficial:
            "service.configuration.deepseek.provider.official"
        case .openCodeGo:
            "service.configuration.deepseek.provider.opencode_go"
        }
    }

    // MARK: Fileprivate

    fileprivate var adapter: any DeepSeekProviderAdapter {
        switch self {
        case .deepSeekOfficial:
            DeepSeekOfficialAdapter()
        case .openCodeGo:
            OpenCodeGoDeepSeekAdapter()
        }
    }
}

// MARK: - DeepSeekProviderAdapter

private protocol DeepSeekProviderAdapter {
    var link: String { get }
    var endpoint: String { get }
    var models: [String] { get }
    var defaultModel: String { get }
    var supportsReasoningEffort: Bool { get }

    func makeRequestBody(
        messages: [ChatMessage],
        model: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) throws
        -> Data
}

extension DeepSeekProviderAdapter {
    fileprivate func encodeRequest(
        messages: [ChatMessage],
        model: String,
        temperature: Double,
        thinking: DeepSeekThinking? = nil,
        reasoningEffort: String? = nil
    ) throws
        -> Data {
        try JSONEncoder().encode(
            DeepSeekChatRequest(
                messages: messages.map(DeepSeekChatMessage.init),
                model: model,
                temperature: temperature,
                stream: true,
                thinking: thinking,
                reasoningEffort: reasoningEffort
            )
        )
    }
}

// MARK: - DeepSeekOfficialAdapter

private struct DeepSeekOfficialAdapter: DeepSeekProviderAdapter {
    static let chatCompletionsEndpoint = "https://api.deepseek.com/v1/chat/completions"

    let link = "https://platform.deepseek.com/"
    let endpoint = Self.chatCompletionsEndpoint
    let models = ["deepseek-flash", "deepseek-v4-pro"]
    let defaultModel = "deepseek-flash"
    let supportsReasoningEffort = true

    func makeRequestBody(
        messages: [ChatMessage],
        model: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) throws
        -> Data {
        try encodeRequest(
            messages: messages,
            model: model,
            temperature: temperature,
            thinking: .init(type: reasoningEffort.isEnabled ? "enabled" : "disabled"),
            reasoningEffort: reasoningEffort.requestValue
        )
    }
}

// MARK: - OpenCodeGoDeepSeekAdapter

private struct OpenCodeGoDeepSeekAdapter: DeepSeekProviderAdapter {
    let link = "https://opencode.ai/v2/docs/console/go"
    let endpoint = "https://opencode.ai/zen/go/v1/chat/completions"
    let models = ["deepseek-v4-flash", "deepseek-v4-pro"]
    let defaultModel = "deepseek-v4-flash"
    let supportsReasoningEffort = false

    func makeRequestBody(
        messages: [ChatMessage],
        model: String,
        temperature: Double,
        reasoningEffort _: ReasoningEffort
    ) throws
        -> Data {
        try encodeRequest(messages: messages, model: model, temperature: temperature)
    }
}

// MARK: - DeepSeekChatRequest

/// Encodable chat-completions payload for DeepSeek. Mirrors the OpenAI-
/// compatible fields Easydict already uses and adds DeepSeek V4's `thinking`
/// and `reasoning_effort` parameters.
private struct DeepSeekChatRequest: Encodable {
    // MARK: Internal

    let messages: [DeepSeekChatMessage]
    let model: String
    let temperature: Double
    let stream: Bool
    let thinking: DeepSeekThinking?
    let reasoningEffort: String?

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case messages
        case model
        case temperature
        case stream
        case thinking
        case reasoningEffort = "reasoning_effort"
    }
}

// MARK: - DeepSeekChatMessage

/// Minimal chat message shape accepted by DeepSeek's OpenAI-compatible
/// endpoint, built from Easydict's provider-agnostic prompt messages.
private struct DeepSeekChatMessage: Encodable {
    // MARK: Lifecycle

    init(_ message: ChatMessage) {
        self.role = message.role.rawValue
        self.content = message.content
    }

    // MARK: Internal

    let role: String
    let content: String
}

// MARK: - DeepSeekThinking

/// DeepSeek V4 thinking mode switch. The effort level is encoded separately
/// because the API keeps `thinking.type` and `reasoning_effort` as sibling
/// parameters.
private struct DeepSeekThinking: Encodable {
    let type: String
}

// MARK: - DeepSeekStreamChunk

/// Streaming chat-completions chunk returned by DeepSeek. Only the assistant
/// content delta is needed for Easydict's text output pipeline.
private struct DeepSeekStreamChunk: Decodable {
    struct Choice: Decodable {
        let delta: Delta
    }

    struct Delta: Decodable {
        let content: String?
    }

    let choices: [Choice]
}
