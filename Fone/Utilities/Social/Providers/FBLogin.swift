//
//  FBLogin.swift
//
//

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit

final class FBLogin {
  
  static let shared: FBLogin = FBLogin()
  private let readPermissions: [String] = ["public_profile", "email"]
  private let graphPermissions: [String: Any] = ["fields": "id, name, email, picture.type(large)"]
  
  func login(
    viewController: UIViewController,
    completion: @escaping SocialLoginResultHandler
  ) {
    print("Facebook login init")
    
    // Clear any previous session
    self.logOut()
    
    let loginManager: LoginManager = LoginManager()
        
    loginManager.logIn(
      permissions: readPermissions,
      from: viewController) { [unowned self] (result, error) in
        if let _error = error {
          print("Facebook login failed with error: \(_error.localizedDescription)")
          completion(.failure(_error))
          return
        }
        
        if let result = result {
          guard !result.isCancelled else {
            print("Facebook login user cancelled the flow")
            completion(.failure(NSError.error(localizedDescription: "Facebook login cancelled")))
            return
          }
          
          let graphRequest: GraphRequest = GraphRequest(
            graphPath: "me",
            parameters: self.graphPermissions
          )
          
          graphRequest.start { _, result, error in
            if let _error = error {
              print("Facebook login graph request failed with error: \(_error.localizedDescription)")
              completion(.failure(_error))
              return
            }
            
            if let result = result as? [String: Any] {
              guard let accessToken = AccessToken.current?.tokenString else {
                completion(.failure(
                  NSError.error(
                    code: 0,
                    localizedDescription: "Failed to retrieve access token")
                  )
                )
                
                return
              }
              
              print("Facebook successfully loggedin")
              
              let userID = result["id"] as? String ?? ""
              let name = result["name"] as? String ?? ""
              let email = result["email"] as? String
              var imageURL: String?
              
              if let picture = result["picture"] as? [String: Any],
                let data = picture["data"] as? [String: Any],
                let url = data["url"] as? String {
                imageURL = url
              }
              var firstName = ""
              var lastName = ""
              let arr = name.components(separatedBy: " ")
              if arr.count > 1 {
                  firstName = arr.first ?? ""
                  lastName = arr.last ?? ""
              } else {
                  firstName = name
              }
              let user = SocialLoginUser(
                id: userID,
                name: name,
                username: nil,
                firstName: firstName,
                lastName: lastName,
                email: email,
                profileImageURL: imageURL,
                authToken: accessToken
              )
              
              completion(.success(user))
            }
          }
        }
    }
  }
  
  func logOut() {
    LoginManager().logOut()
  }
}
