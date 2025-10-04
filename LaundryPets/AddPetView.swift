//
//  AddPetView.swift
//  LaundryPets
//
//  View for creating new pets with name and settings configuration
//

import SwiftUI
import SwiftData

struct AddPetView: View {
    let modelContext: ModelContext
    let petsViewModel: PetsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var petName: String = ""
    @State private var cycleFrequency: Int = 7
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(modelContext: ModelContext, petsViewModel: PetsViewModel) {
        self.modelContext = modelContext
        self.petsViewModel = petsViewModel
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pet Information")) {
                    HStack {
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        TextField("Pet Name", text: $petName)
                            .textFieldStyle(.plain)
                    }
                }
                
                Section(header: Text("Laundry Schedule"), footer: Text("How often this pet needs laundry. Shorter cycles mean more frequent care.")) {
                    Picker("Cycle Frequency", selection: $cycleFrequency) {
                        ForEach(1...99, id: \.self) { days in
                            Text(days == 1 ? "1 day" : "\(days) days")
                                .tag(days)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }
                
                Section(footer: Text("Your pet will start with 100% health and will need laundry care based on the schedule you set.")) {
                    Button(action: createPet) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Pet")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Add Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(petsViewModel.$showError) { showError in
            if showError {
                errorMessage = petsViewModel.errorMessage ?? "An unknown error occurred"
                showingError = true
                petsViewModel.clearError()
            }
        }
    }
    
    // MARK: - Actions
    
    private func createPet() {
        let trimmedName = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a pet name."
            showingError = true
            return
        }
        
        guard trimmedName.count <= 30 else {
            errorMessage = "Pet name must be 30 characters or less."
            showingError = true
            return
        }
        
        if let newPet = petsViewModel.createPet(name: trimmedName, cycleFrequencyDays: cycleFrequency) {
            print("✅ Created new pet: \(newPet.name)")
            dismiss()
        } else {
            errorMessage = "Failed to create pet. Please try again."
            showingError = true
        }
    }
}

// MARK: - Preview

#Preview {
    let modelContext = ModelContext(try! ModelContainer(for: Pet.self, LaundryTask.self, AppSettings.self))
    let petsViewModel = PetsViewModel(modelContext: modelContext)
    
    return AddPetView(modelContext: modelContext, petsViewModel: petsViewModel)
}
