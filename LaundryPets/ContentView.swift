//
//  ContentView.swift
//  LaundryPets
//
//  Created by Walter Magill on 10/1/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        PetDashboardView(modelContext: modelContext)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Pet.self, LaundryTask.self, AppSettings.self])
}
