//
//  ThreeFingerTapRecognizer.swift
//  Easydict
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - ThreeFingerTapRecognizer

/// Recognizes a short, low-movement gesture made with exactly three touches.
///
/// AppKit does not expose a dedicated three-finger lookup event. Generic
/// gesture events expose their touches, which lets this recognizer distinguish
/// a tap from a swipe without linking the private MultitouchSupport framework.
final class ThreeFingerTapRecognizer {
    // MARK: Internal

    enum Result {
        case none
        case began
        case recognized
    }

    /// Consumes one generic gesture event and reports candidate lifecycle changes.
    func consume(_ event: NSEvent) -> Result {
        let touches = event.allTouches()
        let activePhases: NSTouch.Phase = [.began, .moved, .stationary]
        let activeTouches = touches.filter { activePhases.contains($0.phase) }
        let hasCancelledTouch = touches.contains { $0.phase == .cancelled }

        if hasCancelledTouch {
            rejectContactSequence()
            return .none
        }

        return consume(
            positions: activeTouches.map(\.normalizedPosition),
            timestamp: event.timestamp
        )
    }

    /// Consumes one raw trackpad contact frame.
    func consume(positions: [CGPoint], timestamp: TimeInterval) -> Result {
        if positions.isEmpty {
            let result = startedAt == nil ? Result.none : finishCandidate(at: timestamp)
            resetContactSequence()
            return result
        }

        if contactSequenceStartedAt == nil {
            contactSequenceStartedAt = timestamp
        }
        guard !isContactSequenceRejected else { return .none }

        if startedAt == nil, positions.count == 2 {
            let centroid = touchGeometry(positions).centroid
            if let twoFingerStartCentroid,
               hypot(centroid.x - twoFingerStartCentroid.x, centroid.y - twoFingerStartCentroid.y)
               > Constants.maximumTravel
            {
                rejectContactSequence()
                return .none
            }
            if twoFingerStartCentroid == nil {
                twoFingerStartCentroid = centroid
            }
        }

        if startedAt == nil {
            guard positions.count == Constants.touchCount else {
                if positions.count > Constants.touchCount {
                    rejectContactSequence()
                }
                return .none
            }
            guard let contactSequenceStartedAt,
                  timestamp - contactSequenceStartedAt <= Constants.maximumTouchOnset
            else {
                rejectContactSequence()
                return .none
            }
            let geometry = touchGeometry(positions)
            startedAt = timestamp
            startCentroid = geometry.centroid
            startSpread = geometry.spread
            maximumTravel = 0
            isEnding = false
            return .began
        }

        if positions.count < Constants.touchCount {
            isEnding = true
            if positions.count == 2 {
                let centroid = touchGeometry(positions).centroid
                if let endingTwoFingerCentroid,
                   hypot(centroid.x - endingTwoFingerCentroid.x, centroid.y - endingTwoFingerCentroid.y)
                   > Constants.maximumTravel
                {
                    rejectContactSequence()
                    return .none
                }
                if endingTwoFingerCentroid == nil {
                    endingTwoFingerCentroid = centroid
                }
            }
            return .none
        }

        guard positions.count == Constants.touchCount,
              !isEnding,
              let startCentroid
        else {
            rejectContactSequence()
            return .none
        }

        let geometry = touchGeometry(positions)
        let centroidTravel = hypot(
            geometry.centroid.x - startCentroid.x,
            geometry.centroid.y - startCentroid.y
        )
        let spreadTravel = abs(geometry.spread - startSpread)
        maximumTravel = max(maximumTravel, centroidTravel, spreadTravel)

        if maximumTravel > Constants.maximumTravel {
            rejectContactSequence()
        }
        return .none
    }

    func reset() {
        resetCandidate()
        resetContactSequence()
        lastRecognizedAt = 0
    }

    // MARK: Private

    private enum Constants {
        static let touchCount = 3
        static let maximumDuration: TimeInterval = 0.55
        /// A third finger added to an ongoing two-finger gesture is not a tap.
        static let maximumTouchOnset: TimeInterval = 0.15
        /// Touch positions are normalized to the trackpad's 0...1 coordinate space.
        static let maximumTravel: CGFloat = 0.04
        static let debounceInterval: TimeInterval = 0.75
    }

    private var startedAt: TimeInterval?
    private var contactSequenceStartedAt: TimeInterval?
    private var twoFingerStartCentroid: CGPoint?
    private var endingTwoFingerCentroid: CGPoint?
    private var isContactSequenceRejected = false
    private var startCentroid: CGPoint?
    private var startSpread: CGFloat = 0
    private var maximumTravel: CGFloat = 0
    private var isEnding = false
    private var lastRecognizedAt: TimeInterval = 0

    private func touchGeometry(_ positions: [CGPoint]) -> (centroid: CGPoint, spread: CGFloat) {
        let centroid = positions.reduce(CGPoint.zero) { partial, position in
            CGPoint(
                x: partial.x + position.x / CGFloat(positions.count),
                y: partial.y + position.y / CGFloat(positions.count)
            )
        }
        let spread = positions.reduce(CGFloat.zero) { partial, position in
            partial + hypot(
                position.x - centroid.x,
                position.y - centroid.y
            ) / CGFloat(positions.count)
        }
        return (centroid, spread)
    }

    private func finishCandidate(at timestamp: TimeInterval) -> Result {
        guard let startedAt else { return .none }
        let duration = timestamp - startedAt
        let isTap = duration <= Constants.maximumDuration
            && maximumTravel <= Constants.maximumTravel
            && timestamp - lastRecognizedAt >= Constants.debounceInterval
        resetCandidate()
        if isTap {
            lastRecognizedAt = timestamp
        }
        return isTap ? .recognized : .none
    }

    private func resetCandidate() {
        startedAt = nil
        startCentroid = nil
        startSpread = 0
        maximumTravel = 0
        isEnding = false
        endingTwoFingerCentroid = nil
    }

    private func rejectContactSequence() {
        isContactSequenceRejected = true
        resetCandidate()
    }

    private func resetContactSequence() {
        contactSequenceStartedAt = nil
        twoFingerStartCentroid = nil
        isContactSequenceRejected = false
    }
}
