//
//  GoogleLogin.swift
//
//

import Foundation
import GoogleSignIn

class GoogleLogin: NSObject {
  
  static let shared: GoogleLogin = GoogleLogin()
  
  private let clientId = SocialLoginConfiguration.Google.OAuthClientID
  private var handler: SocialLoginResultHandler?
  private var configuration: GIDConfiguration
  
  override init() {
    self.configuration = GIDConfiguration(clientID: clientId)
  }
  
  func login(
    viewController: UIViewController,
    completion: @escaping SocialLoginResultHandler
  ) {
    print("Google login init")
    
    self.handler = completion
    
    GIDSignIn
      .sharedInstance
      .signIn(
        with: configuration,
        presenting: viewController) { [weak self] user, error in
        self?.sign(
          didSignInFor: user,
          withError: error
        )
      }
  }
  
  func logOut() {
    GIDSignIn.sharedInstance.signOut()
  }
  
  // MARK: - Private
  
  private func clear() {
    handler = nil
  }
}

// MARK: - Sign in
extension GoogleLogin {
  
  func sign(didSignInFor user: GIDGoogleUser?, withError error: Error?) {
    
    if let _error = error {
      print("Google login failed with error: \(_error.localizedDescription)")
      handler?(.failure(_error))
      
    } else if let _user = user {
      
      print("Google successfully loggedin")
            
      let socialUser = SocialLoginUser(
        id: _user.userID ?? "",
        name: _user.profile?.name,
        username: nil,
        firstName: _user.profile?.givenName,
        lastName: _user.profile?.familyName,
        email: _user.profile?.email,
        profileImageURL: _user.profile?.imageURL(withDimension: 200)?.absoluteString,
        authToken: _user.authentication.idToken ?? ""
      )
      
      handler?(.success(socialUser))
    }
    
    self.clear()
  }
}