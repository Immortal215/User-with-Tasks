import FirebaseCore
import FirebaseDatabaseInternal
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

struct Club: Codable {
    var leaders: [String] // emails 
    var members: [String] // emails
    var inviteOnly: Bool // can I join the club or do I have to request to join
    var announcements: [String: String]? // each announcement time will be in this form of Date : Body
    var meetingTimes: [String: [String]]? // each meeting time will be in this form of Date : [Title, Body]
    var description: String // short description to catch viewers
    var name: String
    var schoologyCode: String
    var genres: [String]?
    var clubPhoto: String?
    var abstract: String // club abstract (basically a longer description)
    var showDataWho: String // shows sensitive info to : all, allNonGuest, onlyMembers, onlyLeaders
}

struct Personal: Codable {
    var favoritedClubs: [String]
    var subjectPreferences: [String]
    var clubsAPartOf: [String]
}

@MainActor
final class AuthenticationViewModel: ObservableObject {
    var userEmail: String?
    var userName: String?
    var userImage: URL?
    @Published var isGuestUser: Bool = false
    var userType: String?
    
    
    init() {
        if let user = Auth.auth().currentUser {
            self.userEmail = user.email
            self.userName = user.displayName
            self.userImage = user.photoURL
            self.isGuestUser = false
            if let email = user.email {
                self.userType = email.split(separator: ".").contains("d214") ? (email.split(separator: ".").contains("stu") ? "D214 Student" : "D214 Teacher") : "Unknown User"
            }
        }
    }
    
    func signInAsGuest() {
        self.userName = "Guest Account"
        self.userEmail = "Explore!"
        self.userImage = nil
        self.isGuestUser = true
        self.userType = "Guest"
    }
    
    func signInGoogle() async throws {
        guard let topVC = Utilities.shared.topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        guard let idToken = gidSignInResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accesssToken = gidSignInResult.user.accessToken.tokenString
        let name = gidSignInResult.user.profile?.name
        let email = gidSignInResult.user.profile?.email
        let image = gidSignInResult.user.profile?.imageURL(withDimension: 100)
        
        self.userEmail = email
        self.userName = name
        self.userImage = image
        self.isGuestUser = false
        if let email = email {
            self.userType = email.split(separator: ".").contains("d214") ? (email.split(separator: ".").contains("stu") ? "D214 Student" : "D214 Teacher") : "Unknown User"
        }
        
        let tokens = GoogleSignInResultModel(idToken: idToken, accessToken: accesssToken, name: name, email: email, image: image)
        try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
        
    }
    
}

struct GoogleSignInResultModel {
    let idToken : String
    let accessToken: String
    let name: String?
    let email: String?
    let image: URL?
    
}
