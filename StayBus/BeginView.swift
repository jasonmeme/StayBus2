import SwiftUI

struct BeginView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            NavigationView {
                RouteListView()
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Routes")
            }
        
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .environmentObject(authManager)
    }
}

struct BeginView_Previews: PreviewProvider {
    static var previews: some View {
        BeginView()
            .environmentObject(AuthenticationManager.shared)
    }
}
