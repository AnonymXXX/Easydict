#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "xcodeproj"

ROOT = Pathname.new(File.expand_path("../..", __dir__))
PROJECT_PATH = ROOT.join("Easydict.xcodeproj")

REMOVED_SERVICE_DIRECTORIES = %w[
  AITool
  Ali
  Baidu
  Bing
  BuiltInAI
  Caiyun
  Claude
  ClaudeCode
  CodexCLI
  CustomOpenAI
  DeepL
  Dictionary
  Doubao
  Gemini
  GitHub\ Models
  Google
  Groq
  MiniMax
  NiuTrans
  Ollama
  Tencent
  Volcano
  Zhipu
].freeze

REMOVED_APP_SOURCE_PREFIXES = (
  REMOVED_SERVICE_DIRECTORIES.map { |name| "Easydict/Swift/Service/#{name}/" } +
  [
    "Easydict/Swift/Service/Apple/AppleTranslation/",
    "Easydict/Swift/Feature/ActionManager/",
    "Easydict/Swift/Feature/DefaultAPIKeys/",
    "Easydict/Swift/Feature/HTTPServer/",
  ]
).freeze

REMOVED_APP_SOURCE_FILES = %w[
  Easydict/Swift/Service/OpenAI/BaseOpenAIService.swift
  Easydict/Swift/Service/OpenAI/OpenAIService.swift
  Easydict/Swift/Service/OpenAI/OpenAIStreamTransport.swift
  Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/ClaudeCodeServiceConfigurationView.swift
  Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/CodexCLIServiceConfigurationView.swift
  Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/CodexManagedAccountView.swift
  Easydict/Swift/View/SettingView/Tabs/TabView/PrivacyTab.swift
].freeze

REMOVED_TEST_PREFIXES = %w[
  EasydictTests/Service/ClaudeCode/
  EasydictTests/Service/CodexCLI/
  EasydictTests/Service/OpenAI/
].freeze

REMOVED_TEST_FILES = %w[
  EasydictTests/Service/AppleLanguageDetectorTests.swift
  EasydictTests/Service/AppleServiceTests.swift
  EasydictTests/Service/BingServiceTests.swift
  EasydictTests/Service/ClaudeSSEParserTests.swift
  EasydictTests/Service/DeepLServiceTests.swift
  EasydictTests/Service/MDictReaderTests.swift
  EasydictTests/Service/ServiceTests.swift
].freeze

REMOVED_RESOURCE_PREFIXES = %w[
  Easydict/Swift/Service/Dictionary/
  Easydict/Swift/Service/Google/
  Easydict/Swift/Service/Youdao/Model/DictJSONExample/
].freeze

REMOVED_RESOURCE_FILES = %w[
  Easydict/Swift/Feature/DefaultAPIKeys/EncryptedSecretKeys.plist
  Easydict/App/GoogleService-Info.plist
].freeze

REMOVED_PACKAGE_PRODUCTS = %w[
  FirebaseAnalytics
  GoogleGenerativeAI
  OpenAI
  Sentry
  Sparkle
  AsyncAlgorithms
  Vapor
].freeze

REMOVED_PACKAGE_URL_FRAGMENTS = %w[
  firebase-ios-sdk
  generative-ai-swift
  MacPaw/OpenAI
  sentry-cocoa
  SimplyDanny/SwiftLintPlugins
  sparkle-project/Sparkle
  vapor/vapor
  apple/swift-async-algorithms
].freeze

REMOVED_SHELL_PHASES = [
  "Format",
  "Lint",
  "Prepare bundled Codex",
  "Upload Debug Symbols to Sentry",
].freeze

def relative_path(file_ref)
  Pathname.new(file_ref.real_path.to_s).relative_path_from(ROOT).to_s
rescue ArgumentError
  file_ref.real_path.to_s
end

def matches?(path, prefixes:, files:)
  files.include?(path) || prefixes.any? { |prefix| path.start_with?(prefix) }
end

def remove_build_files(phase, prefixes:, files:)
  phase.files.dup.each do |build_file|
    file_ref = build_file.file_ref
    next unless file_ref

    path = relative_path(file_ref)
    next unless matches?(path, prefixes: prefixes, files: files)

    puts "remove membership: #{path}"
    build_file.remove_from_project
  end
end

project = Xcodeproj::Project.open(PROJECT_PATH)
app_target = project.targets.find { |target| target.name == "Easydict" }
test_target = project.targets.find { |target| target.name == "EasydictTests" }

abort "Easydict target not found" unless app_target
abort "EasydictTests target not found" unless test_target

remove_build_files(
  app_target.source_build_phase,
  prefixes: REMOVED_APP_SOURCE_PREFIXES,
  files: REMOVED_APP_SOURCE_FILES
)
remove_build_files(
  test_target.source_build_phase,
  prefixes: REMOVED_TEST_PREFIXES,
  files: REMOVED_TEST_FILES
)
remove_build_files(
  app_target.resources_build_phase,
  prefixes: REMOVED_RESOURCE_PREFIXES,
  files: REMOVED_RESOURCE_FILES
)

app_target.frameworks_build_phase.files.dup.each do |build_file|
  product_name = build_file.product_ref&.product_name
  next unless REMOVED_PACKAGE_PRODUCTS.include?(product_name)

  puts "remove linked package product: #{product_name}"
  build_file.remove_from_project
end

app_target.package_product_dependencies.dup.each do |dependency|
  next unless REMOVED_PACKAGE_PRODUCTS.include?(dependency.product_name)

  puts "remove package dependency: #{dependency.product_name}"
  dependency.remove_from_project
end

project.root_object.package_references.dup.each do |package|
  url = package.repositoryURL.to_s
  next unless REMOVED_PACKAGE_URL_FRAGMENTS.any? { |fragment| url.include?(fragment) }

  puts "remove remote package: #{url}"
  package.remove_from_project
end

app_target.shell_script_build_phases.dup.each do |phase|
  next unless REMOVED_SHELL_PHASES.include?(phase.name)

  puts "remove shell phase: #{phase.name}"
  phase.remove_from_project
end

app_target.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings["PRODUCT_NAME"] = "Easydict Lite"
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = if configuration.name == "Debug"
                                               "com.anonymxxx.EasydictLite-debug"
                                             else
                                               "com.anonymxxx.EasydictLite"
                                             end
  settings["ARCHS"] = "arm64" if configuration.name == "Release"
end

test_target.build_configurations.each do |configuration|
  configuration.build_settings["TEST_HOST"] =
    "$(BUILT_PRODUCTS_DIR)/Easydict Lite.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Easydict Lite"
end

project.save
puts "configured #{PROJECT_PATH} for Easydict Lite"
