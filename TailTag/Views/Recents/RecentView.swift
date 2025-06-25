import SwiftUI

struct RecentView: View {
    @EnvironmentObject var spottingStore: SpottingStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var showingAddView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if spottingStore.entries.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            HStack {
                                Text("Most recent")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                            
                            ForEach(spottingStore.mostRecentEntries) { entry in
                                SpottingCardView(entry: entry)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("TailTag")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingAddView) {
            AddSpottingView()
        }
    }
}

