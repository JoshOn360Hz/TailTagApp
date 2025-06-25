import SwiftUI

struct SearchView: View {
    @EnvironmentObject var spottingStore: SpottingStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var searchText = ""
    
    var filteredEntries: [SpottingEntry] {
        spottingStore.filteredEntries(searchText: searchText).sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search registration, airline, or aircraft...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                if spottingStore.entries.isEmpty {
                    EmptyStateView()
                } else if searchText.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(spottingStore.entries) { entry in
                                SpottingCardView(entry: entry)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                } else if filteredEntries.isEmpty {
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
                            ForEach(filteredEntries) { entry in
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
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    SearchView()
        .environmentObject(SpottingStore())
        .environmentObject(AppSettings())
}
