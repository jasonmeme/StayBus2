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
    @State private var selectedStopId: String?
    @State private var notificationTime: Int = 5
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = NotificationViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Stop")) {
                    Picker("Stop", selection: $selectedStopId) {
                        ForEach(route.stops) { stop in
                            Text("\(stop.stopNumber): \(stop.location)")
                                .tag(stop.id as String?)
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
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text(viewModel.alertTitle),
                      message: Text(viewModel.alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func scheduleNotification() {
        guard let stopId = selectedStopId,
              let stop = route.stops.first(where: { $0.id == stopId }) else {
            viewModel.showAlert(title: "Error", message: "Please select a stop")
            return
        }
        
        viewModel.scheduleNotification(for: route, stop: stop, minutesBefore: notificationTime)
    }
}

class NotificationViewModel: ObservableObject {
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    func scheduleNotification(for route: Route, stop: StopModel, minutesBefore: Int) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                self.createNotification(for: route, stop: stop, minutesBefore: minutesBefore)
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Permission Denied", message: "Please enable notifications in Settings to use this feature.")
                }
            }
        }
    }
    
    private func createNotification(for route: Route, stop: StopModel, minutesBefore: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Bus Arriving Soon"
        content.body = "Your bus for \(route.name) will arrive at \(stop.location) in \(minutesBefore) minutes."
        content.sound = UNNotificationSound.default
        
        // Convert stop time to Date and subtract minutesBefore
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        guard let stopTime = dateFormatter.date(from: stop.time) else {
            DispatchQueue.main.async {
                self.showAlert(title: "Error", message: "Invalid stop time format")
            }
            return
        }
        
        let calendar = Calendar.current
        guard let notificationDate = calendar.date(byAdding: .minute, value: -minutesBefore, to: stopTime) else {
            DispatchQueue.main.async {
                self.showAlert(title: "Error", message: "Could not calculate notification time")
            }
            return
        }
        
        let components = calendar.dateComponents([.hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "Error", message: "Failed to schedule notification: \(error.localizedDescription)")
                } else {
                    self.showAlert(title: "Success", message: "Notification scheduled successfully")
                }
            }
        }
    }
}
