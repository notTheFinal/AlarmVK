import Foundation
import UserNotifications
import AVFoundation

final class AlarmManager: ObservableObject {
    @Published private(set) var alarms: [UNNotificationRequest] = []
    @Published private(set) var authorizationStatus: UNAuthorizationStatus?
    
    func reloadAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { isGranted, _ in
            DispatchQueue.main.async {
                self.authorizationStatus = isGranted ? .authorized : .denied
            }
        }
    }
    
    func reloadAlarms() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { alarms in
            DispatchQueue.main.async {
                self.alarms = alarms
            }
        }
    }
    
    func createAlarm(title: String, hour: Int, minute: Int, days: [Day], completion: @escaping (Error?) -> Void) {
        var subscribedDays: [Int] = []
        for day in days {
            if day.isSubscribed {
                subscribedDays.append(day.numberOfDay)
            }
        }
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        
        
        let alarmContent = UNMutableNotificationContent()
        alarmContent.title = title
        alarmContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "mp3.caf"))
        alarmContent.sound = nil
        alarmContent.body = "Блудильник"
        
        if subscribedDays.count == 7 {
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: alarmContent, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request, withCompletionHandler: completion)
        } else {
            for day in subscribedDays {
                dateComponents.weekday = day
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: alarmContent, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: completion)
            }
        }
    }
    
    func deleteAlarms(identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
