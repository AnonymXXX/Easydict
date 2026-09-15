//
//  ServiceTab.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/6.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// MARK: - ServiceTab

struct ServiceTab: View {
    // MARK: Internal

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 8) {
                Text("setting.service.translation_services")
                    .font(.headline)

                List(
                    selection: Binding(
                        get: { viewModel.selectedItem },
                        set: { viewModel.selectItem($0) }
                    )
                ) {
                    ServiceItems()
                }
                .listStyle(.plain)
                .scrollIndicators(.never)
                .borderedCard()
                .onReceive(serviceHasUpdatedNotification) { _ in
                    viewModel.updateServices()
                }
            }
            .padding(12)
            .frame(minWidth: 270, maxWidth: 320, maxHeight: .infinity)

            ServiceDetailView()
                .layoutPriority(1)
        }
        .environmentObject(viewModel)
    }

    // MARK: Private

    @StateObject private var viewModel: ServiceTabViewModel = .init()

    private let serviceHasUpdatedNotification = NotificationCenter.default
        .publisher(for: .serviceHasUpdated)
}

// MARK: - ServiceTabSelection

enum ServiceTabSelection: Hashable {
    case service(String)
}

// MARK: - ServiceTabViewModel

@MainActor
class ServiceTabViewModel: ObservableObject {
    // MARK: Lifecycle

    init(windowType: EZWindowType = .fixed) {
        self.windowType = windowType
        self.serviceItems = Self.loadServiceItems(windowType)
        self.selectedItem = Self.preferredSelection(in: serviceItems)
        updateSelectedService()
    }

    // MARK: Internal

    @Published private(set) var serviceItems: [ServiceListItem]

    @Published private(set) var selectedService: QueryService?

    @Published private(set) var selectedItem: ServiceTabSelection?

    let windowType: EZWindowType

    func updateServices() {
        let previousSelection = selectedItem
        serviceItems = Self.loadServiceItems(windowType)

        let selection = previousSelection.flatMap { selection in
            serviceItems.contains { item in
                selection == .service(item.id)
            } ? selection : nil
        }
        setSelection(selection ?? Self.preferredSelection(in: serviceItems))
    }

    func moveServices(fromOffsets: IndexSet, toOffset: Int) {
        var serviceItems = serviceItems
        serviceItems.move(fromOffsets: fromOffsets, toOffset: toOffset)

        let serviceTypes = serviceItems.map(\.id)
        LocalStorage.shared().setAllServiceTypes(serviceTypes, windowType: windowType)

        postUpdateServiceNotification()
        updateServices()
    }

    func selectItem(_ item: ServiceTabSelection?) {
        setSelection(item ?? Self.preferredSelection(in: serviceItems))
    }

    func setServiceEnabled(_ enabled: Bool, for item: ServiceListItem) {
        if selectedService?.serviceTypeWithUniqueIdentifier() == item.id {
            selectedService?.enabled = enabled
            if let selectedService {
                LocalStorage.shared().setService(selectedService, windowType: windowType)
            }
        } else {
            LocalStorage.shared().setServiceEnabled(
                enabled,
                serviceTypeId: item.id,
                windowType: windowType
            )
        }

        postUpdateServiceNotification()
        reloadLLMSubscribersIfNeeded(for: [item])
        updateServices()
    }

    func postUpdateServiceNotification() {
        NotificationCenter.default.postServiceUpdateNotification(windowType: windowType)
    }

    // MARK: Private

    private static func loadServiceItems(_ windowType: EZWindowType) -> [ServiceListItem] {
        serviceItems(from: LocalStorage.shared().allServiceTypes(windowType), windowType: windowType)
    }

    private static func serviceItems(
        from serviceTypeIds: [String],
        windowType: EZWindowType
    )
        -> [ServiceListItem] {
        serviceTypeIds.compactMap { typeId in
            guard let metadata = QueryServiceFactory.shared.metadata(withTypeId: typeId) else {
                return nil
            }
            let info = LocalStorage.shared().serviceInfo(
                withType: metadata.serviceType,
                serviceId: metadata.uuid,
                windowType: windowType
            )
            return ServiceListItem(
                id: typeId,
                type: metadata.serviceType,
                name: metadata.title,
                enabled: info?.enabled == true,
                requirement: metadata.apiKeyRequirement,
                isStream: metadata.isStream
            )
        }
    }

    private func updateSelectedService() {
        guard case let .service(serviceID) = selectedItem else {
            selectedService = nil
            return
        }
        guard serviceItems.contains(where: { $0.id == serviceID }) else {
            selectedService = nil
            return
        }
        selectedService = LocalStorage.shared().service(serviceID, windowType: windowType)
    }

    private static func preferredSelection(in items: [ServiceListItem]) -> ServiceTabSelection? {
        let preferredItem = items.first { $0.type == .deepSeek } ?? items.first
        return preferredItem.map { .service($0.id) }
    }

    private func setSelection(_ selection: ServiceTabSelection?) {
        selectedItem = selection
        updateSelectedService()
    }

    private func reloadLLMSubscribersIfNeeded(for items: [ServiceListItem]) {
        // Stream configuration observers cover all window memberships, so any
        // window can add or remove a service that changes the observed union.
        guard items.contains(where: { $0.isStream }) else { return }
        GlobalContext.shared.reloadLLMServicesSubscribers()
    }
}

// MARK: - ServiceListItem

struct ServiceListItem: Identifiable {
    let id: String
    let type: ServiceType
    let name: String
    let enabled: Bool
    let requirement: ServiceAPIKeyRequirement
    let isStream: Bool
}

// MARK: - ServiceDetailView

private struct ServiceDetailView: View {
    // MARK: Internal

    var body: some View {
        Group {
            if let service = viewModel.selectedService {
                if let view = service.configurationListItems() as? (any View) {
                    Form {
                        AnyView(view)
                    }
                    .formStyle(.grouped)
                } else {
                    VStack {
                        Spacer()

                        Text("setting.service.detail.no_configuration \(service.name())")

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel
}
