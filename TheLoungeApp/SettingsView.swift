import SwiftUI
import UserNotifications

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var serverURL: String {
        didSet {
            UserDefaults.standard.set(serverURL, forKey: "serverURL")
            NotificationCenter.default.post(name: .serverURLChanged, object: nil)
        }
    }

    @Published var titlebarColor: Color {
        didSet {
            saveTitlebarColor()
            NotificationCenter.default.post(name: .titlebarColorChanged, object: nil)
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    @Published var notificationSound: Bool {
        didSet {
            UserDefaults.standard.set(notificationSound, forKey: "notificationSound")
        }
    }

    init() {
        // Load server URL
        self.serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? "https://irc.pulina.fi"

        // Load titlebar color
        if let colorData = UserDefaults.standard.data(forKey: "titlebarColor"),
           let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            self.titlebarColor = Color(nsColor)
        } else {
            // Default: #010a0d
            self.titlebarColor = Color(red: 1/255, green: 10/255, blue: 13/255)
        }

        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.notificationSound = UserDefaults.standard.object(forKey: "notificationSound") as? Bool ?? true
    }

    private func saveTitlebarColor() {
        let nsColor = NSColor(titlebarColor)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: "titlebarColor")
        }
    }

    func getNSColor() -> NSColor {
        return NSColor(titlebarColor)
    }

    func getServerURL() -> URL {
        return URL(string: serverURL) ?? URL(string: "https://irc.pulina.fi")!
    }
}

extension Notification.Name {
    static let titlebarColorChanged = Notification.Name("titlebarColorChanged")
    static let serverURLChanged = Notification.Name("serverURLChanged")
}

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var notificationStatus: String = "Checking..."

    var body: some View {
        TabView {
            // General Tab
            Form {
                Section {
                    TextField("Server URL", text: $settings.serverURL)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 4)

                    Text("Enter the full URL of your The Lounge instance. Restart the app after changing.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Server")
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gear")
            }

            // Appearance Tab
            Form {
                Section {
                    ColorPicker("Titlebar Color", selection: $settings.titlebarColor, supportsOpacity: false)
                        .padding(.vertical, 4)

                    Button("Reset to Default") {
                        settings.titlebarColor = Color(red: 1/255, green: 10/255, blue: 13/255)
                    }
                } header: {
                    Text("Appearance")
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Appearance", systemImage: "paintbrush")
            }

            // Notifications Tab
            Form {
                Section {
                    Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                        .padding(.vertical, 2)

                    Toggle("Play Sound", isOn: $settings.notificationSound)
                        .padding(.vertical, 2)
                        .disabled(!settings.notificationsEnabled)
                } header: {
                    Text("Notification Settings")
                }

                Section {
                    HStack {
                        Text("System Permission:")
                        Spacer()
                        Text(notificationStatus)
                            .foregroundColor(.secondary)
                    }

                    Button("Request Permission") {
                        requestNotificationPermission()
                    }

                    Button("Test Notification") {
                        sendTestNotification()
                    }
                    .disabled(!settings.notificationsEnabled)
                } header: {
                    Text("Test & Permissions")
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Notifications", systemImage: "bell")
            }
            .onAppear {
                checkNotificationStatus()
            }
        }
        .frame(width: 450, height: 300)
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    notificationStatus = "Authorized"
                case .denied:
                    notificationStatus = "Denied"
                case .notDetermined:
                    notificationStatus = "Not Requested"
                case .provisional:
                    notificationStatus = "Provisional"
                case .ephemeral:
                    notificationStatus = "Ephemeral"
                @unknown default:
                    notificationStatus = "Unknown"
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                checkNotificationStatus()
            }
        }
    }

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Notifications are working correctly!"
        if settings.notificationSound {
            content.sound = .default
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending test notification: \(error)")
            }
        }
    }
}

#Preview {
    SettingsView()
}
