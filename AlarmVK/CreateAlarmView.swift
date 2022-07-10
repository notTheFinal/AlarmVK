import SwiftUI
import AVFoundation

struct Day: Identifiable {
    var id: String
    var isSubscribed = false
    var numberOfDay: Int
}

var audioPlayer: AVAudioPlayer!

struct CreateAlarmView: View {
    @ObservedObject var alarmManager: AlarmManager
    @State private var title = ""
    @State private var date = Date()
    
    @State var lists = [
        Day(id: "Понедельник", isSubscribed: true, numberOfDay: 1),
        Day(id: "Вторник", isSubscribed: true, numberOfDay: 2),
        Day(id: "Среда", isSubscribed: true, numberOfDay: 3),
        Day(id: "Четверг", isSubscribed: true, numberOfDay: 4),
        Day(id: "Пятница", isSubscribed: true, numberOfDay: 5),
        Day(id: "Суббота", isSubscribed: true, numberOfDay: 6),
        Day(id: "Воскресенье", isSubscribed: true, numberOfDay: 7)
    ]
    
    @State var falseB = false
    @Binding var isPresented: Bool
    @State var showingAlert = false
    
    private func getTime(to time: Date) -> Float {
        let timeNow = Date().timeIntervalSince1970
        let timeEvent = Double(Int(time.timeIntervalSince1970 / 60) * 60)

        if Float(timeEvent - timeNow) > 0 {
            return Float(timeEvent - timeNow)
//            return 1.0
        } else {
            return Float(timeEvent - timeNow) + 86400.0
//            return 1.0
        }

    }
    
    private func getAlarm() {
        let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playback, mode: .default, options: [])
            } catch {
                print("Failed to set audio session category.")
            }
        let sound = Bundle.main.url(forResource: "music", withExtension: "mp3")
        guard sound != nil else {return}
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: sound!)
            audioPlayer?.play()
            showingAlert = true
            AlarmListView(bridge: $showingAlert)
            alarmManager.reloadAlarms()
        } catch {
            print("alert")
        }
    }
    
    private func update() {
        for alarm in alarmManager.alarms {
            guard let nextTriggerDate = (alarm.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() else { return }
            Timer.scheduledTimer(withTimeInterval: TimeInterval(getTime(to: nextTriggerDate)), repeats: false, block: { _ in
                showingAlert = true
                getAlarm()
            })
        }
    }
    
    
    var body: some View {
        
        List {
            Section {
                VStack(spacing: 16) {
                    HStack {
                        TextField("Alarm Title", text: $title)
                        Spacer()
                            .accessibilityLabel("Label")
                        DatePicker("", selection: $date, displayedComponents: [.hourAndMinute])
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .cornerRadius(5)
                    
                    ForEach($lists) { $list in
                        Toggle(list.id, isOn: $list.isSubscribed)
                    }
                    
                    if #available(iOS 15.0, *) {
                        Button {
                            let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
                            guard let hour = dateComponents.hour, let minute = dateComponents.minute else { return }
                           
                            
                            Task {
                                let _ = await alarmManager.createAlarm(title: title, hour: hour, minute: minute, days: lists) { error in
                                    
                                }
                                await alarmManager.reloadAlarms()
                    
                            }
                            
                            
                            
                            
                        } label: {
                            Text("Create")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                        }
                        
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(5)
                        .buttonStyle(PlainButtonStyle())
                        
                        Button{
                            self.isPresented = false
                            update()
                            AlarmListView(bridge: $showingAlert)
                        } label: {
                            Text("Close")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                        }
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(5)
                        .buttonStyle(PlainButtonStyle())
                        
                    } else {}
                }
                .listRowBackground(Color(.systemGroupedBackground))
            }
        }
        .listStyle(InsetGroupedListStyle())
        .onDisappear {
            alarmManager.reloadAlarms()
        }
        .navigationTitle("Create")
        .navigationBarItems(trailing: Button {
            isPresented = false
        } label: {
            Image(systemName: "xmark")
                .imageScale(.large)
        })
    }
}

struct CreateAlarmView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAlarmView(
            alarmManager: AlarmManager(),
            isPresented: .constant(false)
        )
    }
}
