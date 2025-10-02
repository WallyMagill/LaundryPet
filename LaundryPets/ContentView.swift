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
        // Phase 2 Testing - Will be replaced with real UI in Phase 3
        TestViewModelsView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Pet.self, LaundryTask.self, AppSettings.self])
}
