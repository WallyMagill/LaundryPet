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
        TestModelsView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Pet.self, LaundryTask.self, AppSettings.self])
}
