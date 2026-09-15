//
//  RawTrackpadMonitor.swift
//  Easydict
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import CoreFoundation
import Foundation

// MARK: - RawTrackpadMonitor

/// Reads trackpad contact frames without suppressing or replacing macOS gestures.
///
/// The system's Quick Look gesture does not enter the normal AppKit event queue.
/// MultitouchSupport is therefore loaded dynamically and treated as optional so
/// an unavailable private framework never prevents Easydict from launching.
final class RawTrackpadMonitor {
    // MARK: Internal

    enum StartResult {
        case started(deviceCount: Int)
        case unavailable(reason: String)
    }

    var touchFrameHandler: (([CGPoint], TimeInterval) -> ())?

    func start() -> StartResult {
        guard devices.isEmpty else { return .started(deviceCount: devices.count) }
        guard loadFunctions() else {
            return .unavailable(reason: lastError ?? "MultitouchSupport is unavailable")
        }
        guard let createDeviceList,
              let registerContactFrameCallback,
              let startDevice,
              let unmanagedDeviceList = createDeviceList()
        else {
            return .unavailable(reason: "MultitouchSupport returned no device list")
        }

        let deviceList = unmanagedDeviceList.takeUnretainedValue()
        let count = CFArrayGetCount(deviceList)
        var candidates: [UnsafeMutableRawPointer] = []
        var fallbackCandidates: [UnsafeMutableRawPointer] = []

        for index in 0..<count {
            guard let rawDevice = CFArrayGetValueAtIndex(deviceList, index) else { continue }
            let device = UnsafeMutableRawPointer(mutating: rawDevice)
            fallbackCandidates.append(device)
            if isTrackpad(device) {
                candidates.append(device)
            }
        }

        if candidates.isEmpty {
            // Older framework variants may not expose device classification.
            // Starting all endpoints is safe because non-trackpad devices cannot
            // produce the three simultaneous contacts required by the recognizer.
            candidates = fallbackCandidates
        }
        guard !candidates.isEmpty else {
            return .unavailable(reason: "No multitouch devices were found")
        }

        Self.activeMonitor = self
        for device in candidates {
            registerContactFrameCallback(device, rawTrackpadFrameCallback)
            startDevice(device, 0)
        }
        devices = candidates
        return .started(deviceCount: candidates.count)
    }

    func stop() {
        if let unregisterContactFrameCallback {
            for device in devices {
                unregisterContactFrameCallback(device, rawTrackpadFrameCallback)
            }
        }
        if let stopDevice {
            for device in devices {
                stopDevice(device)
            }
        }
        devices.removeAll()
        if Self.activeMonitor === self {
            Self.activeMonitor = nil
        }
    }

    // MARK: Private

    private struct MTPoint {
        let x: Float
        let y: Float
    }

    private struct MTReadout {
        let position: MTPoint
        let velocity: MTPoint
    }

    /// ABI layout used by the contact callback in MultitouchSupport.
    private struct MTContact {
        let frame: Int32
        let timestamp: Double
        let identifier: Int32
        let state: Int32
        let fingerID: Int32
        let handID: Int32
        let normalized: MTReadout
        let size: Float
        let zero1: Int32
        let angle: Float
        let majorAxis: Float
        let minorAxis: Float
        let millimeters: MTReadout
        let zero2: (Int32, Int32)
        let unknown: Float
    }

    private typealias CreateDeviceListFunction = @convention(c) () -> Unmanaged<CFArray>?
    fileprivate typealias ContactFrameCallback = @convention(c) (
        UnsafeMutableRawPointer?,
        UnsafeMutableRawPointer?,
        Int32,
        Double,
        Int32
    ) -> Int32
    private typealias RegisterContactFrameCallbackFunction = @convention(c) (
        UnsafeMutableRawPointer?,
        ContactFrameCallback
    ) -> Void
    private typealias StartDeviceFunction = @convention(c) (UnsafeMutableRawPointer?, Int32) -> Void
    private typealias StopDeviceFunction = @convention(c) (UnsafeMutableRawPointer?) -> Void
    private typealias DevicePredicateFunction = @convention(c) (UnsafeMutableRawPointer?) -> Bool

    fileprivate static weak var activeMonitor: RawTrackpadMonitor?

    private var frameworkHandle: UnsafeMutableRawPointer?
    private var createDeviceList: CreateDeviceListFunction?
    private var registerContactFrameCallback: RegisterContactFrameCallbackFunction?
    private var unregisterContactFrameCallback: RegisterContactFrameCallbackFunction?
    private var startDevice: StartDeviceFunction?
    private var stopDevice: StopDeviceFunction?
    private var deviceIsBuiltIn: DevicePredicateFunction?
    private var deviceSupportsForce: DevicePredicateFunction?
    private var devices: [UnsafeMutableRawPointer] = []
    private var lastError: String?

    private func loadFunctions() -> Bool {
        if frameworkHandle != nil { return true }
        let paths = [
            "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport",
            "/System/Library/PrivateFrameworks/MultitouchSupport.framework/Versions/Current/MultitouchSupport",
        ]
        frameworkHandle = paths.lazy.compactMap {
            dlopen($0, RTLD_LAZY | RTLD_LOCAL)
        }.first
        guard let frameworkHandle else {
            lastError = dlerror().map { String(cString: $0) }
            return false
        }

        createDeviceList = loadSymbol("MTDeviceCreateList", from: frameworkHandle)
        registerContactFrameCallback = loadSymbol("MTRegisterContactFrameCallback", from: frameworkHandle)
        unregisterContactFrameCallback = loadSymbol("MTUnregisterContactFrameCallback", from: frameworkHandle)
        startDevice = loadSymbol("MTDeviceStart", from: frameworkHandle)
        stopDevice = loadSymbol("MTDeviceStop", from: frameworkHandle)
        deviceIsBuiltIn = loadSymbol("MTDeviceIsBuiltIn", from: frameworkHandle)
        deviceSupportsForce = loadSymbol("MTDeviceSupportsForce", from: frameworkHandle)

        guard createDeviceList != nil,
              registerContactFrameCallback != nil,
              startDevice != nil
        else {
            lastError = "MultitouchSupport is missing required symbols"
            return false
        }
        return true
    }

    private func loadSymbol<T>(_ name: String, from handle: UnsafeMutableRawPointer) -> T? {
        guard let symbol = dlsym(handle, name) else { return nil }
        return unsafeBitCast(symbol, to: T.self)
    }

    private func isTrackpad(_ device: UnsafeMutableRawPointer) -> Bool {
        let isBuiltIn = deviceIsBuiltIn?(device) ?? false
        let supportsForce = deviceSupportsForce?(device) ?? false
        return isBuiltIn || supportsForce
    }

    fileprivate func receiveFrame(
        contacts: UnsafeMutableRawPointer?,
        contactCount: Int32,
        timestamp: TimeInterval
    ) {
        var positions: [CGPoint] = []
        if let contacts, contactCount > 0 {
            let typedContacts = contacts.assumingMemoryBound(to: MTContact.self)
            positions.reserveCapacity(Int(contactCount))
            for index in 0..<Int(contactCount) {
                let contact = typedContacts.advanced(by: index).pointee
                positions.append(
                    CGPoint(
                        x: CGFloat(contact.normalized.position.x),
                        y: CGFloat(contact.normalized.position.y)
                    )
                )
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.touchFrameHandler?(positions, timestamp)
        }
    }
}

private let rawTrackpadFrameCallback: RawTrackpadMonitor.ContactFrameCallback = {
    _, contacts, contactCount, timestamp, _ in
    RawTrackpadMonitor.activeMonitor?.receiveFrame(
        contacts: contacts,
        contactCount: contactCount,
        timestamp: timestamp
    )
    return 0
}
