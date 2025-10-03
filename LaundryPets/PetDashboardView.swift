//
//  PetDashboardView.swift
//  LaundryPets
//
//  Main dashboard view displaying all pets in a beautiful grid layout
//  Features pixel-perfect design, real-time updates, and comprehensive interactions
//

import SwiftUI
import SwiftData

struct PetDashboardView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var petsViewModel: PetsViewModel
    @State private var showingAddPet = false
    @State private var showingSettings = false
    @State private var petToDelete: Pet?
    @State private var showingDeleteConfirmation = false
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self._petsViewModel = StateObject(wrappedValue: PetsViewModel(modelContext: modelContext))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Header Section
                        headerSection
                        
                        // Pet Cards Grid
                        petCardsSection
                        
                        // Stats Section
                        statsSection
                        
                        // Bottom Padding
                        Color.clear
                            .frame(height: 20)
                    }
                }
                .refreshable {
                    petsViewModel.refreshPets()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddPet) {
            AddPetView(modelContext: modelContext, petsViewModel: petsViewModel)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(modelContext: modelContext)
        }
        .alert("Error", isPresented: $petsViewModel.showError) {
            Button("OK") {
                petsViewModel.clearError()
            }
        } message: {
            Text(petsViewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert("Delete Pet", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let pet = petToDelete {
                    petsViewModel.deletePet(pet)
                    petToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                petToDelete = nil
            }
        } message: {
            if let pet = petToDelete {
                Text("Are you sure you want to delete \(pet.name)? This action cannot be undone and will also delete all associated laundry tasks.")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Navigation Bar (Height: 44pt)
            HStack(spacing: 0) {
                // Left: Add Pet Button
                Button("Add Pet") {
                    showingAddPet = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                .frame(height: 32)
                .frame(minWidth: 80)
                
                Spacer(minLength: 16)
                
                // Right: Settings Button
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            
            // App Title Section with enhanced styling
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Laundry Time")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Keep your pets happy and healthy")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .frame(height: 80) // Total header height
    }
    
    // MARK: - Pet Cards Section
    
    private var petCardsSection: some View {
        Group {
            if petsViewModel.pets.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sortedPets) { pet in
                        PetCardView(pet: pet, modelContext: modelContext) { petToDelete in
                            self.petToDelete = petToDelete
                            self.showingDeleteConfirmation = true
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            // Stats Header
            HStack {
                Text("Your Progress")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Stats Cards
            HStack(spacing: 12) {
                // Best Streak Card
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    
                    Text("Best Streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("\(bestStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("days")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Current Streak Card
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                    
                    Text("Current Streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("\(currentStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("days")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 24)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))
            
            // Title
            Text("No Pets Yet")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)
            
            // Description
            Text("Create your first pet to start your laundry journey!")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            // Action Button
            Button("Add Your First Pet") {
                showingAddPet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.system(size: 16, weight: .medium))
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
    
    // MARK: - Computed Properties
    
    /// Pets sorted by creation date (oldest first)
    private var sortedPets: [Pet] {
        petsViewModel.pets.sorted { $0.createdDate < $1.createdDate }
    }
    
    /// Best streak across all pets
    private var bestStreak: Int {
        petsViewModel.pets.map { $0.longestStreak }.max() ?? 0
    }
    
    /// Current streak across all pets
    private var currentStreak: Int {
        petsViewModel.pets.map { $0.currentStreak }.max() ?? 0
    }
}



// MARK: - Preview

#Preview {
    let modelContext = ModelContext(try! ModelContainer(for: Pet.self, LaundryTask.self, AppSettings.self))
    
    return PetDashboardView(modelContext: modelContext)
}
