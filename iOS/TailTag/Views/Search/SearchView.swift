import SwiftUI

struct SearchView: View {
    @EnvironmentObject var spottingStore: SpottingStore
    @EnvironmentObject var appSettings: AppSettings
    @Binding private var searchText: String
    private let usesLocalSearchField: Bool
    @State private var selectedSortOption: SortOption = .dateNewest
    
    init(searchText: Binding<String>, usesLocalSearchField: Bool = true) {
        _searchText = searchText
        self.usesLocalSearchField = usesLocalSearchField
    }
    
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
                        
                        Text("No spottings match \"\(searchText)\"")
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if !searchText.isEmpty {
                                HStack {
                                    Text("Results for \"\(searchText)\"")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(filteredAndSortedEntries.count)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            }
                            
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
            .modifier(SearchableIfNeeded(isEnabled: usesLocalSearchField, searchText: $searchText))
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

private struct SearchableIfNeeded: ViewModifier {
    let isEnabled: Bool
    @Binding var searchText: String

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $searchText, prompt: "Search aircraft, airlines, places...")
        } else {
            content
        }
    }
}
