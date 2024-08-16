//
//  NotificationSetupView.swift
//  StayBus
//
//  Created by Jason Zhu on 8/16/24.
//

import SwiftUI
import UserNotifications

struct NotificationSetupView: View {
    @Binding var route: Route
    @State private var selectedStop: Stop?
    @State private var notificationTime: Int = 5
    
    var body: some View {
        Form {
            Section(header: Text("Select Stop")) {
                Picker("Stop", selection: $selectedStop) {
                    ForEach(route.stops) { stop in
                        Text("\(stop.stopNumber): \(stop.location)").tag(Optional(stop))
                    }
                }
            }
            
            Section(header: Text("Notification Time")) {
                Stepper(value: $notificationTime, in: 1...30) {
                    Text("Notify \(notificationTime) minutes before arrival")
                }
            }
            
            Section {
                Button(action: scheduleNotification) {
                    Text("Set Notification")
                }
            }
        }
        .navigationTitle("Set Notification")
    }
    
    func scheduleNotification() {
        guard let stop = selectedStop else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Bus Arriving Soon"
        content.body = "Your bus for \(route.name) will arrive at \(stop.location) in \(notificationTime) minutes."
        content.sound = UNNotificationSound.default
        
        // Convert stop time to Date and subtract notificationTime
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        guard let stopTime = dateFormatter.date(from: stop.time) else { return }
        
        let calendar = Calendar.current
        guard let notificationDate = calendar.date(byAdding: .minute, value: -notificationTime, to: stopTime) else { return }
        
        let components = calendar.dateComponents([.hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
}
