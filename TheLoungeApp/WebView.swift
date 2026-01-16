import SwiftUI
import WebKit
import UserNotifications

class WebViewStore: ObservableObject {
    static let shared = WebViewStore()
    var webView: WKWebView?

    func zoomIn() {
        guard let webView = webView else { return }
        webView.pageZoom += 0.1
    }

    func zoomOut() {
        guard let webView = webView else { return }
        webView.pageZoom = max(0.5, webView.pageZoom - 0.1)
    }

    func resetZoom() {
        webView?.pageZoom = 1.0
    }
}

struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        // Add message handler for notifications
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "notificationHandler")
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }

        // Comprehensive notification bridge for The Lounge
        // Fully mocks Push API, Service Workers, and Notification API
        let notificationBridge = """
        (function() {
            // Track if we're "subscribed" to push notifications
            let pushSubscribed = false;
            let mockSubscription = null;

            // Helper to send notification to native
            function sendNativeNotification(title, options) {
                try {
                    window.webkit.messageHandlers.notificationHandler.postMessage({
                        type: 'show',
                        title: title || 'The Lounge',
                        body: options?.body || options?.message || '',
                        tag: options?.tag || ''
                    });
                } catch(e) {
                    console.log('Native notification error:', e);
                }
            }

            // Create a mock PushSubscription
            function createMockSubscription() {
                const subscriptionId = 'native-app-' + Date.now();
                return {
                    endpoint: 'https://native-app.local/push/' + subscriptionId,
                    expirationTime: null,
                    options: {
                        applicationServerKey: new ArrayBuffer(65),
                        userVisibleOnly: true
                    },
                    getKey: function(name) {
                        // Return mock keys
                        if (name === 'p256dh') return new ArrayBuffer(65);
                        if (name === 'auth') return new ArrayBuffer(16);
                        return null;
                    },
                    toJSON: function() {
                        return {
                            endpoint: this.endpoint,
                            expirationTime: this.expirationTime,
                            keys: {
                                p256dh: 'mock-p256dh-key-base64',
                                auth: 'mock-auth-key-base64'
                            }
                        };
                    },
                    unsubscribe: function() {
                        pushSubscribed = false;
                        mockSubscription = null;
                        return Promise.resolve(true);
                    }
                };
            }

            // Create mock PushManager
            function createMockPushManager() {
                return {
                    getSubscription: function() {
                        return Promise.resolve(pushSubscribed ? mockSubscription : null);
                    },
                    subscribe: function(options) {
                        pushSubscribed = true;
                        mockSubscription = createMockSubscription();
                        console.log('Push subscription created (native app mock)');
                        return Promise.resolve(mockSubscription);
                    },
                    permissionState: function() {
                        return Promise.resolve('granted');
                    }
                };
            }

            // Create mock ServiceWorkerRegistration
            function createMockRegistration() {
                return {
                    installing: null,
                    waiting: null,
                    active: {
                        state: 'activated',
                        scriptURL: '/service-worker.js',
                        postMessage: function() {},
                        addEventListener: function() {},
                        removeEventListener: function() {}
                    },
                    scope: '/',
                    updateViaCache: 'none',
                    pushManager: createMockPushManager(),
                    sync: {
                        register: function() { return Promise.resolve(); },
                        getTags: function() { return Promise.resolve([]); }
                    },
                    addEventListener: function(type, listener) {},
                    removeEventListener: function(type, listener) {},
                    update: function() { return Promise.resolve(this); },
                    unregister: function() { return Promise.resolve(true); },
                    showNotification: function(title, options) {
                        sendNativeNotification(title, options);
                        return Promise.resolve();
                    },
                    getNotifications: function() { return Promise.resolve([]); }
                };
            }

            // Mock ServiceWorkerContainer
            const mockRegistration = createMockRegistration();

            if ('serviceWorker' in navigator) {
                // Override serviceWorker.register
                const originalRegister = navigator.serviceWorker.register;
                navigator.serviceWorker.register = function(scriptURL, options) {
                    console.log('Service Worker registration mocked for native app:', scriptURL);
                    return Promise.resolve(mockRegistration);
                };

                // Override serviceWorker.ready
                Object.defineProperty(navigator.serviceWorker, 'ready', {
                    get: function() {
                        return Promise.resolve(mockRegistration);
                    }
                });

                // Override serviceWorker.getRegistration
                navigator.serviceWorker.getRegistration = function() {
                    return Promise.resolve(mockRegistration);
                };

                // Override serviceWorker.getRegistrations
                navigator.serviceWorker.getRegistrations = function() {
                    return Promise.resolve([mockRegistration]);
                };
            }

            // Create custom Notification class
            class NativeNotification {
                constructor(title, options) {
                    this.title = title;
                    this.options = options || {};
                    this.body = this.options.body || '';
                    this.tag = this.options.tag || '';
                    this.onclick = null;
                    this.onclose = null;
                    this.onerror = null;
                    this.onshow = null;

                    // Send to native
                    sendNativeNotification(title, options);

                    // Trigger onshow
                    setTimeout(() => {
                        if (this.onshow) this.onshow();
                    }, 0);
                }

                close() {
                    if (this.onclose) this.onclose();
                }

                addEventListener(type, listener) {
                    if (type === 'click') this.onclick = listener;
                    if (type === 'close') this.onclose = listener;
                    if (type === 'error') this.onerror = listener;
                    if (type === 'show') this.onshow = listener;
                }

                removeEventListener(type, listener) {}

                static get permission() {
                    return 'granted';
                }

                static requestPermission(callback) {
                    if (callback) callback('granted');
                    return Promise.resolve('granted');
                }
            }

            // Replace window.Notification
            window.Notification = NativeNotification;

            // Monitor WebSocket for incoming IRC messages that should trigger notifications
            const OriginalWebSocket = window.WebSocket;
            window.WebSocket = function(url, protocols) {
                const ws = protocols ? new OriginalWebSocket(url, protocols) : new OriginalWebSocket(url);

                ws.addEventListener('message', function(event) {
                    try {
                        const data = event.data;
                        if (typeof data === 'string' && data.startsWith('42')) {
                            const jsonStr = data.substring(2);
                            try {
                                const parsed = JSON.parse(jsonStr);
                                if (Array.isArray(parsed) && parsed[0] === 'msg') {
                                    const msgData = parsed[1];
                                    // Check if this is a highlight or PM that should notify
                                    if (msgData && msgData.msg && msgData.msg.highlight) {
                                        const msg = msgData.msg;
                                        const from = msg.from?.nick || msg.from || 'Someone';
                                        const text = msg.text || '';
                                        sendNativeNotification(from, {
                                            body: text,
                                            tag: 'thelounge-highlight'
                                        });
                                    }
                                }
                            } catch(e) {}
                        }
                    } catch(e) {}
                });

                return ws;
            };
            window.WebSocket.prototype = OriginalWebSocket.prototype;
            window.WebSocket.CONNECTING = OriginalWebSocket.CONNECTING;
            window.WebSocket.OPEN = OriginalWebSocket.OPEN;
            window.WebSocket.CLOSING = OriginalWebSocket.CLOSING;
            window.WebSocket.CLOSED = OriginalWebSocket.CLOSED;

            console.log('The Lounge native notification bridge initialized (full Push API mock)');
        })();
        """

        let script = WKUserScript(source: notificationBridge, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(script)

        // Store reference for zoom controls
        WebViewStore.shared.webView = webView

        // Load the URL
        webView.load(URLRequest(url: url))

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No need to update
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        // Handle messages from JavaScript
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "notificationHandler" {
                if let dict = message.body as? [String: Any],
                   let type = dict["type"] as? String,
                   type == "show",
                   let title = dict["title"] as? String {

                    let body = dict["body"] as? String ?? ""

                    // Show native notification
                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = body
                    content.sound = .default

                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error showing notification: \(error)")
                        }
                    }
                }
            }
        }

        // Handle navigation - open external links in browser
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                // Allow navigation to irc.pulina.fi
                if let host = url.host, host.contains("pulina.fi") {
                    decisionHandler(.allow)
                    return
                }

                // If it's a different domain and a link click, open in browser
                if navigationAction.navigationType == .linkActivated {
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }

            decisionHandler(.allow)
        }

        // Handle navigation completion
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Disable spell checking via JavaScript
            let disableSpellCheck = """
            document.documentElement.spellcheck = false;
            document.body.spellcheck = false;
            var elements = document.getElementsByTagName('*');
            for (var i = 0; i < elements.length; i++) {
                if (elements[i].tagName === 'INPUT' ||
                    elements[i].tagName === 'TEXTAREA' ||
                    elements[i].isContentEditable) {
                    elements[i].spellcheck = false;
                    elements[i].setAttribute('spellcheck', 'false');
                }
            }

            var observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.nodeType === 1) {
                            if (node.tagName === 'INPUT' ||
                                node.tagName === 'TEXTAREA' ||
                                node.isContentEditable) {
                                node.spellcheck = false;
                                node.setAttribute('spellcheck', 'false');
                            }
                            var children = node.getElementsByTagName('*');
                            for (var i = 0; i < children.length; i++) {
                                if (children[i].tagName === 'INPUT' ||
                                    children[i].tagName === 'TEXTAREA' ||
                                    children[i].isContentEditable) {
                                    children[i].spellcheck = false;
                                    children[i].setAttribute('spellcheck', 'false');
                                }
                            }
                        }
                    });
                });
            });
            observer.observe(document.body, { childList: true, subtree: true });
            """
            webView.evaluateJavaScript(disableSpellCheck, completionHandler: nil)
        }

        // Handle new windows - open in browser
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
            }
            return nil
        }
    }
}
