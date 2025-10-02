//
//  ContentView.swift
//  LaundryPets
//
//  Created by Walter Magill on 10/1/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        // Phase 1 Testing - Will be replaced with real UI in Phase 2
        TestModelsView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Pet.self, LaundryTask.self, AppSettings.self])
}
