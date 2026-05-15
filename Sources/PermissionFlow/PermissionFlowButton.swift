#if os(macOS)
import AppKit
import SwiftUI

@available(macOS 13.0, *)
public struct PermissionFlowButton: View {
    @Environment(\.locale) var locale
    @StateObject private var controller: PermissionFlowController
    @State private var buttonState: PermissionFlowButtonState
    @State private var buttonFrameInScreen: CGRect?
    private let pane: PermissionFlowPane
    private let suggestedAppURLs: [URL]
    private let title: LocalizedStringResource?

    public init(
        title: LocalizedStringResource? = nil,
        pane: PermissionFlowPane,
        suggestedAppURLs: [URL] = [],
        configuration: PermissionFlowConfiguration = .init()
    ) {
        _controller = StateObject(wrappedValue: PermissionFlowController(configuration: configuration))
        self.pane = pane
        self.suggestedAppURLs = suggestedAppURLs
        self.title = title
        
        // Initialize with checking state, will be updated on appear
        _buttonState = State(initialValue: PermissionFlowButtonState.make(from: .checking))
    }

    public var body: some View {
        Button {
            let sourceFrame = clickSourceFrameInScreen()
            controller.setLocaleIdentifier(locale.identifier)
            controller.authorize(
                pane: pane,
                suggestedAppURLs: suggestedAppURLs,
                sourceFrameInScreen: sourceFrame
            )
        } label: {
            Label {
                Text(title ?? LocalizedStringResource(String.LocalizationValue(buttonState.titleKey), locale: locale, bundle: .module))
            } icon: {
                Image(systemName: buttonState.systemImage)
                    .foregroundColor(buttonState.isGranted ? .green : .primary)
            }
        }
        .onAppear(perform: refreshAuthorizationStatus)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshAuthorizationStatus()
        }
        .background(ScreenFrameReader(frame: $buttonFrameInScreen))
    }

    /// Uses the actual button bounds instead of the latest mouse location.
    /// This keeps the launch source stable when hosted inside AppKit or when
    /// the click event is forwarded indirectly.
    private func clickSourceFrameInScreen() -> CGRect {
        buttonFrameInScreen ?? .zero
    }

    private func refreshAuthorizationStatus() {
        let provider = PermissionStatusRegistry.provider(for: pane)
        let authState = provider.authorizationState()
        buttonState = PermissionFlowButtonState.make(from: authState)
    }
}

@available(macOS 13.0, *)
private struct ScreenFrameReader: NSViewRepresentable {
    @Binding var frame: CGRect?

    func makeNSView(context: Context) -> FrameReadingView {
        let view = FrameReadingView()
        view.onFrameChange = { newFrame in
            guard frame != newFrame else { return }
            DispatchQueue.main.async {
                frame = newFrame
            }
        }
        return view
    }

    func updateNSView(_ nsView: FrameReadingView, context: Context) {
        nsView.onFrameChange = { newFrame in
            guard frame != newFrame else { return }
            DispatchQueue.main.async {
                frame = newFrame
            }
        }
        nsView.publishFrame()
    }
}

@available(macOS 13.0, *)
private final class FrameReadingView: NSView {
    var onFrameChange: ((CGRect?) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        publishFrame()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        publishFrame()
    }

    override func setFrameOrigin(_ newOrigin: NSPoint) {
        super.setFrameOrigin(newOrigin)
        publishFrame()
    }

    func publishFrame() {
        guard let window else {
            onFrameChange?(nil)
            return
        }

        let frameInWindow = convert(bounds, to: nil)
        let frameInScreen = window.convertToScreen(frameInWindow)
        onFrameChange?(frameInScreen)
    }
}
#endif
