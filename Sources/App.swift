import AppKit
import SwiftUI

@main
struct FluentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("show_menu_bar_icon") private var showMenuBarIcon = true

    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBarIcon) {
            MenuBarView()
                .environmentObject(appDelegate.appState)
        } label: {
            MenuBarLabel()
                .environmentObject(appDelegate.appState)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
struct MenuBarLabel: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var notificationManager = VocabularyNotificationManager.shared

    var body: some View {
        HStack(spacing: 4) {
            if notificationManager.showCheckmark {
                Image(systemName: "checkmark")
            }
            if appState.isRecording {
                Image(systemName: "record.circle")
            } else if appState.isTranscribing {
                Image(systemName: "ellipsis.circle")
            } else {
                // Idle: the Fluent brand glyph (speech bubble + waveform).
                // Dev builds get a small marker dot so they're easy to tell
                // apart from a release build running side by side.
                Image(nsImage: AppBuild.isDevBundle
                    ? FluentMenuBarIcon.devTemplateImage
                    : FluentMenuBarIcon.templateImage)
                    .renderingMode(.template)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: notificationManager.showCheckmark)
    }
}

/// The menu bar status icon, drawn as a monochrome template so macOS can tint
/// it correctly for light and dark menu bars. It is a line-art interpretation
/// of the Fluent app icon: a speech-bubble ring with a flowing waveform inside.
/// The app icon (`AppIcon.icns`) is the full-color dock/Finder icon and is not
/// used here, because menu bar items should be simple monochrome glyphs.
enum FluentMenuBarIcon {
    static let templateImage: NSImage = makeImage(markDev: false)
    static let devTemplateImage: NSImage = makeImage(markDev: true)

    private static func makeImage(markDev: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 16)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setStroke()
            NSColor.black.setFill()

            let center = NSPoint(x: 8.8, y: 8.7)
            let radius: CGFloat = 6.0

            // Speech-bubble ring, left slightly open at the lower-left so the
            // tail can flow out of it like the logo.
            let ring = NSBezierPath()
            ring.appendArc(withCenter: center, radius: radius,
                           startAngle: 232, endAngle: 200, clockwise: false)
            ring.lineWidth = 1.5
            ring.lineCapStyle = .round
            ring.stroke()

            // Tail: a short flick out of the lower-left of the bubble.
            let tail = NSBezierPath()
            tail.move(to: NSPoint(x: 4.7, y: 4.3))
            tail.curve(to: NSPoint(x: 2.7, y: 2.4),
                       controlPoint1: NSPoint(x: 4.0, y: 3.4),
                       controlPoint2: NSPoint(x: 3.5, y: 2.8))
            tail.lineWidth = 1.5
            tail.lineCapStyle = .round
            tail.stroke()

            // Waveform squiggle across the middle, echoing the logo's flowing
            // line: a low start, rising to a tall central peak, then easing down.
            let wave = NSBezierPath()
            wave.move(to: NSPoint(x: 5.0, y: 7.9))
            wave.line(to: NSPoint(x: 6.6, y: 10.4))
            wave.line(to: NSPoint(x: 7.9, y: 8.0))
            wave.line(to: NSPoint(x: 9.2, y: 11.1))
            wave.line(to: NSPoint(x: 10.7, y: 8.0))
            wave.line(to: NSPoint(x: 12.6, y: 9.6))
            wave.lineWidth = 1.5
            wave.lineJoinStyle = .round
            wave.lineCapStyle = .round
            wave.stroke()

            if markDev {
                // Small filled dot at the top-right to denote the dev build.
                NSBezierPath(ovalIn: NSRect(x: 14.0, y: 12.0, width: 3.2, height: 3.2)).fill()
            }

            return true
        }
        image.isTemplate = true
        return image
    }
}
