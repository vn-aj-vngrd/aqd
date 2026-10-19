import CoreMotion
import Foundation
import Observation

/// How far the phone is tilted from where the owner is holding it, in -1...1 on each axis. Used only for decorative parallax.
/// The resting position slowly follows the hand, so the effect recentres instead of drifting away. Device motion needs no permission.
@MainActor @Observable final class DeviceTilt {
    private(set) var x: Double = 0
    private(set) var y: Double = 0
    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var restPitch: Double?
    @ObservationIgnored private var restRoll: Double = 0

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let attitude = motion?.attitude else { return }
            self.update(pitch: attitude.pitch, roll: attitude.roll)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        restPitch = nil; x = 0; y = 0
    }

    private func update(pitch: Double, roll: Double) {
        guard let rest = restPitch else { restPitch = pitch; restRoll = roll; return }
        // About 20 degrees of tilt reaches the edge of the range.
        let range = 0.35
        let targetX = max(-1, min(1, (roll - restRoll) / range))
        let targetY = max(-1, min(1, (pitch - rest) / range))
        x += (targetX - x) * 0.12
        y += (targetY - y) * 0.12
        restPitch = rest + (pitch - rest) * 0.004
        restRoll += (roll - restRoll) * 0.004
    }
}
