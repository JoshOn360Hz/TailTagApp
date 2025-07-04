import SwiftUI

struct SearchView: View {
    @EnvironmentObject var spottingStore: SpottingStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var searchText = ""
    @State private var selectedSortOption: SortOption = .dateNewest
    
    var filteredAndSortedEntries: [SpottingEntry] {
        spottingStore.filteredAndSortedEntries(searchText: searchText, sortOption: selectedSortOption)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if spottingStore.entries.isEmpty {
                    EmptyStateView()
                } else if searchText.isEmpty && spottingStore.entries.isEmpty {
                    EmptyStateView()
                } else if !searchText.isEmpty && filteredAndSortedEntries.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("No Results")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("No spottings match your search")
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(searchText.isEmpty ? spottingStore.sortedEntries(by: selectedSortOption) : filteredAndSortedEntries) { entry in
                                SpottingCardView(entry: entry)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search aircraft, airlines...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $selectedSortOption) {
                            ForEach(SortOption.allCases) { option in
                                Label(option.rawValue, systemImage: option.icon)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}


