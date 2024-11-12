import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI
import FirebaseDatabase
import Pow

struct ClubView: View {
    @State var clubs: [Club] = []
    @State var userInfo: Personal? = nil
    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    @AppStorage("shownInfo") var shownInfo = -1
    @State var searchText = ""
    var viewModel: AuthenticationViewModel
    @AppStorage("selectedTab") var selectedTab = 3
    @State var createClubToggler = false
    
    var body: some View {
        
        var filteredItems: [Club] {
            
            // add other filter stuff like clickable buttons for genres
            if searchText.isEmpty {
                return clubs
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    .sorted {
                        userInfo?.favoritedClubs.contains($0.clubID) ?? false &&
                        !(userInfo?.favoritedClubs.contains($1.clubID) ?? false)
                    }
                
            } else {
                return clubs
                    .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    .sorted {
                        userInfo?.favoritedClubs.contains($0.clubID) ?? false &&
                        !(userInfo?.favoritedClubs.contains($1.clubID) ?? false)
                    }
            }
        }
        
        var whoCanSeeWhat: Bool {
            guard shownInfo >= 0, shownInfo < clubs.count else { return false }
            
            switch clubs[shownInfo].showDataWho {
            case "all":
                return true
            case "allNonGuest":
                return !viewModel.isGuestUser
            case "onlyMembers":
                return (clubs[shownInfo].members.contains(viewModel.userEmail ?? "") ||
                        clubs[shownInfo].leaders.contains(viewModel.userEmail ?? ""))
            case "onlyLeaders":
                return clubs[shownInfo].leaders.contains(viewModel.userEmail ?? "")
            default:
                return false
            }
        }
        
        VStack {
            Text("Clubs")
                .font(.title)
            
            HStack {
                
                VStack {
                    HStack {
                        CustomSearchBar(text: $searchText, placeholder: "Search all clubs")
                        if viewModel.userEmail == "sharul.shah2008@gmail.com" {
                            Button {
                                createClubToggler = true
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundStyle(.green)
                            }
                            .sheet(isPresented: $createClubToggler) {
                                CreateClubView(userEmail: viewModel.userEmail!, viewCloser: {
                                    createClubToggler = false
                                })
                            }
                        }
                    }
                    
                    // clubs view
                    ScrollView {
                        
                        
                        
                        ForEach(Array(filteredItems.enumerated()), id: \.element.name) { (index, club) in
                            Button {
                                if shownInfo != clubs.firstIndex(where: { $0.clubID == club.clubID }) ?? -1 {
                                    shownInfo = clubs.firstIndex(where: { $0.clubID == club.clubID }) ?? -1
                                } else {
                                    shownInfo = -1
                                }
                                
                            } label : {
                                
                                // each club
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(.black, lineWidth: 3)
                                    
                                    HStack {
                                        AsyncImage(url: URL(string: club.clubPhoto ?? "https://img.freepik.com/premium-photo/abstract-geometric-white-background-with-isometric-random-boxes_305440-1089.jpg"), content: { Image in
                                            ZStack {
                                                Image
                                                    .resizable()
                                                    .clipShape(Rectangle())
                                                
                                                if club.clubPhoto == nil {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 5)
                                                        
                                                        Text(club.name)
                                                            .padding()
                                                            .foregroundStyle(.white)
                                                    }
                                                    .fixedSize()
                                                }
                                                
                                                Rectangle()
                                                    .stroke(.black, lineWidth: 3)
                                            }
                                            .frame(maxWidth: screenWidth/5, maxHeight: screenHeight/5)
                                            
                                        }, placeholder: {
                                            ZStack {
                                                Rectangle()
                                                    .stroke(.gray)
                                                ProgressView("Loading \(club.name) Image")
                                            }
                                        })
                                        .padding()
                                        
                                        Spacer()
                                        
                                        VStack {
                                            Text(club.name)
                                                .font(.callout)
                                            Text(club.description)
                                                .font(.caption)
                                            Spacer()
                                            if let genres = club.genres, !genres.isEmpty {
                                                Text("Genres: \(genres.joined(separator: ", "))")
                                                    .font(.footnote)
                                                    .foregroundStyle(.blue)
                                            }
                                        }
                                        .padding()
                                        .foregroundStyle(.black)
                                        .frame(width: screenWidth/6)
                                        
                                        VStack {
                                            
                                            // info button
                                            Button {
                                                // shownInfo = index
                                                
                                                shownInfo = clubs.firstIndex(where: { $0.clubID == club.clubID }) ?? -1
                                            } label: {
                                                Image(systemName: club.leaders.contains(viewModel.userEmail ?? "") ? "pencil.circle" : "info.circle")
                                            }
                                            
                                            
                                            // favorite button
                                            if !viewModel.isGuestUser {
                                                Button {
                                                    if userInfo?.favoritedClubs.contains(club.clubID) ?? false {
                                                        removeClubFromFavorites(for: viewModel.uid ?? "", clubID: club.clubID)
                                                        if let UserID = viewModel.uid {
                                                            fetchUser(for: UserID) { user in
                                                                userInfo = user
                                                            }
                                                        }
                                                        dropper(title: "Club Unfavorited", subtitle: club.name, icon: UIImage(systemName: "heart"))
                                                    } else {
                                                        addClubToFavorites(for: viewModel.uid ?? "", clubID: club.clubID)
                                                        if let UserID = viewModel.uid {
                                                            fetchUser(for: UserID) { user in
                                                                userInfo = user
                                                            }
                                                        }
                                                        dropper(title: "Club Favorited", subtitle: club.name, icon: UIImage(systemName: "heart.fill"))
                                                        
                                                    }
                                                    
                                                } label: {
                                                    if userInfo?.favoritedClubs.contains(club.clubID) ?? false {
                                                        Image(systemName: "heart.fill")
                                                            .transition(.movingParts.pop(.blue))
                                                    } else {
                                                        Image(systemName: "heart")
                                                            .transition(.identity)
                                                    }
                                                    
                                                }
                                                .padding(.top)
                                            }
                                        }
                                        .padding()
                                        .padding(.bottom, screenWidth/10)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 3)
                            }
                            .conditionalEffect(
                                .pushDown,
                                condition: shownInfo == clubs.firstIndex(where: { $0.clubID == club.clubID }) ?? -1
                            )
                            
                            
                        }
                        
                        if filteredItems.isEmpty {
                            Text("No Clubs Found for \"\(searchText)\"")
                        }
                        
                        
                        Text("Search for Other Clubs! 🙃")
                            .frame(height: screenHeight/3, alignment: .top)
                        
                    }
                    .frame(width: screenWidth/2)
                    .padding()
                }
                
                // club info view
                ScrollView {
                    if shownInfo >= 0 && shownInfo < clubs.count {
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .center) {
                                Text(clubs[shownInfo].name)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text(clubs[shownInfo].abstract)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                
                                AsyncImage(url: URL(string: clubs[shownInfo].clubPhoto ?? "https://img.freepik.com/premium-photo/abstract-geometric-white-background-with-isometric-random-boxes_305440-1089.jpg"), content: { Image in
                                    ZStack {
                                        Image
                                            .resizable()
                                            .clipShape(Rectangle())
                                        
                                        if clubs[shownInfo].clubPhoto == nil {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 5)
                                                    .foregroundStyle(.blue)
                                                
                                                Text(clubs[shownInfo].name)
                                                    .padding()
                                                    .foregroundStyle(.white)
                                            }
                                            .fixedSize()
                                        }
                                        
                                        Rectangle()
                                            .stroke(.black, lineWidth: 3)
                                    }
                                    .frame(width: screenWidth/5, height: screenHeight/5)
                                    
                                }, placeholder: {
                                    ZStack {
                                        Rectangle()
                                            .stroke(.gray)
                                        ProgressView("Loading \(clubs[shownInfo].name) Image")
                                    }
                                })
                                .padding()
                                .frame(width: screenWidth/5, height: screenHeight/5)
                            }
                            
                            if !clubs[shownInfo].leaders.isEmpty {
                                Text("Leaders (\(clubs[shownInfo].leaders.count)):")
                                    .font(.headline)
                                ForEach(clubs[shownInfo].leaders, id: \.self) { leader in
                                    CodeSnippetView(code: leader)
                                }
                            }
                            
                            if whoCanSeeWhat {
                                if !clubs[shownInfo].members.isEmpty {
                                    var mem = clubs[shownInfo].members.joined(separator: ", ")
                                    
                                    Text("Members (\(clubs[shownInfo].members.count)):")
                                        .font(.headline)
                                    
                                    CodeSnippetView(code: mem)
                                }
                                
                                if let meetingTimes = clubs[shownInfo].meetingTimes {
                                    Text("Meeting Times:")
                                        .font(.headline)
                                    ForEach(meetingTimes.keys.sorted(), id: \.self) { day in
                                        if let times = meetingTimes[day] {
                                            Text("\(day): \(times.joined(separator: ", "))")
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                
                                if let announcements = clubs[shownInfo].announcements {
                                    Text("Announcements:")
                                        .font(.headline)
                                    ForEach(announcements.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        Text("\(key): \(value)")
                                            .font(.subheadline)
                                    }
                                }
                            }
                            
                            if let genres = clubs[shownInfo].genres, !genres.isEmpty {
                                Text("Genres:")
                                    .font(.headline)
                                Text(genres.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                            
                            Text("Location:")
                                .font(.headline)
                            Text(clubs[shownInfo].location)
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                            
                            HStack {
                                Text("Schoology Code: ")
                                CodeSnippetView(code: clubs[shownInfo].schoologyCode)
                            }
                        }
                        .padding()
                    } else {
                        Text("Choose a Club!")
                    }
                    
                    Color.white
                        .frame(height: screenHeight/3)
                }
                .frame(maxWidth: screenWidth/2)
                .padding(.trailing)
            }
        }
        .onAppear {
            fetchClubs { fetchedClubs in
                self.clubs = fetchedClubs
            }
            
            if !viewModel.isGuestUser {
                if let UserID = viewModel.uid {
                    fetchUser(for: UserID) { user in
                        userInfo = user
                    }
                }
            }
        }
        .onPencilDoubleTap(perform: { PencilDoubleTapGestureValue in
            shownInfo = -1
        })
    }
}
