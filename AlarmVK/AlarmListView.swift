import SwiftUI
import AVFoundation
import InstantSearchVoiceOverlay

struct AlarmListView: View {
    @Binding var bridge: Bool
    @StateObject private var alarmManager = AlarmManager()
    @State private var isCreatePresented = false
    @State var voiceOverlayController = VoiceOverlayController()
    
    private static var alarmDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    private static var alarmDateFormatter2: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .long
        
        return dateFormatter
    }()
    
    
    private func timeDisplayText(from alarm: UNNotificationRequest) -> String {
        guard let nextTriggerDate = (alarm.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() else { return "" }
        return Self.alarmDateFormatter.string(from: nextTriggerDate)
    }
    
    private func timeDisplayText2(from alarm: UNNotificationRequest) -> Int {
        guard let nextTriggerDate = (alarm.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() else { return 0 }
        return Calendar.current.component(.weekday, from: nextTriggerDate)
    }
    
    private func numberToWeekday(from number: Int) -> String {
        switch number {
        case 1:
            return "Воскресенье"
        case 2:
            return "Понедельник"
        case 3:
            return "Вторник"
        case 4:
            return "Среда"
        case 5:
            return "Четверг"
        case 6:
            return "Пятница"
        default:
            return "Суббота"
        }
    }
    
    @ViewBuilder
    var infoOverlayView: some View {
        switch alarmManager.authorizationStatus {
        case .authorized:
            if alarmManager.alarms.isEmpty {
                InfoOverlayView(
                    infoMessage: "No Alarms Yet",
                    buttonTitle: "Create",
                    systemImageName: "plus.circle",
                    action: {
                        isCreatePresented = true
                    }
                )
            }
        case .denied:
            InfoOverlayView(
                infoMessage: "Please Enable Alarm Permission In Settings",
                buttonTitle: "Settings",
                systemImageName: "gear",
                action: {
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            )
        default:
            EmptyView()
        }
    }
    
    var body: some View {
        if #available(iOS 15.0, *) {
            VStack {
                Button {
                    voiceOverlayController.start(on: UIHostingController(rootView: AlarmListView), textHandler: {text, final, _ in
                        if final {
                            print("Text: \(text)")
                        } else {
                            print("In Progress: \(text)")
                        }
                    }, errorHandler: {error in
                        
                    })
                    
                } label: {
                    Image(systemName: "mic.fill")
                        .imageScale(.large)
                }
            
            List {
                ForEach(alarmManager.alarms, id: \.identifier) { alarm in
                    HStack {
                        Text(alarm.content.title)
                            .fontWeight(.semibold)
                        Text(timeDisplayText(from: alarm))
                            .fontWeight(.bold)
                        Spacer()
                        Text(numberToWeekday(from: timeDisplayText2(from: alarm)))
                            .fontWeight(.bold)
                    }
                }
                .onDelete(perform: delete)
            }
            .listStyle(InsetGroupedListStyle())
            .overlay(infoOverlayView)
            .navigationTitle("Alarms")
            .onAppear(perform: alarmManager.reloadAuthorizationStatus)
            .onChange(of: alarmManager.authorizationStatus) { authorizationStatus in
                switch authorizationStatus {
                case .notDetermined:
                    alarmManager.requestAuthorization()
                case .authorized:
                    alarmManager.reloadAlarms()
                default:
                    break
                }
            }
            .onChange(of: bridge) { _ in
                
            }
            
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                alarmManager.reloadAuthorizationStatus()
            }
            .navigationBarItems(leading: Button {
                isCreatePresented = true
            } label: {
                Image(systemName: "plus.circle")
                    .imageScale(.large)
            },
            trailing: Button("СТОП", action: {
                guard let player = audioPlayer else { return }
                if player.isPlaying {
                    player.stop()
                }
            }))
            .sheet(isPresented: $isCreatePresented) {
                NavigationView {
                    CreateAlarmView(
                        alarmManager: alarmManager,
                        isPresented: $isCreatePresented
                    )
                }
                
                .accentColor(.primary)
            }
            .alert("Будильник", isPresented: $bridge) {
                Button("STOP", role: .cancel) {
                    bridge = false
                }
            }}
            
            
        } else {
            // Fallback on earlier versions
        }
    }
}

struct PageVC: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        return pageViewController
    }
    
    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        uiViewController.setViewControllers([controllers[0]], direction: .forward, animated: true)
    }
    
    typealias UIViewControllerType = UIPageViewController
    
    var controllers: [UIViewController] = []
    
}

extension AlarmListView {
    func delete(_ indexSet: IndexSet) {
        alarmManager.deleteAlarms(
            identifiers: indexSet.map { alarmManager.alarms[$0].identifier }
        )
        alarmManager.reloadAlarms()
    }
}

