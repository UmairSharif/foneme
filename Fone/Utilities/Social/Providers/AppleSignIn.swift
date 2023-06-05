//
//  AppleSignIn.swift
//  Sain
//
//  Created by Sid lowanshi on 16/10/21.
//

import Foundation
import AuthenticationServices

class AppleSignIn: NSObject {
  
  static let shared: AppleSignIn = AppleSignIn()
  
  private var handler: SocialLoginResultHandler?
  
  func login(
    _ viewController: UIViewController,
    completion: @escaping SocialLoginResultHandler
  ) {
    self.handler = completion
    handleAppleIdRequest()
  }
}

extension AppleSignIn {
  
  func handleAppleIdRequest() {
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    let authorizationController = ASAuthorizationController(authorizationRequests: [request])
    authorizationController.delegate = self
    authorizationController.performRequests()
  }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignIn: ASAuthorizationControllerDelegate {
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    handler?(.failure(error))
  }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
                        
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: KeychainItem.currentUserIdentifier) { (credentialState, error) in
                switch credentialState {
                case .authorized:
                    self.saveDataOnKeyChain(isDataStore: true, appleIDCredential: appleIDCredential)
                case .revoked, .notFound:
                    self.saveDataOnKeyChain(isDataStore: false, appleIDCredential: appleIDCredential)
                    
                default:
                    break
                }
            }
            
        case let passwordCredential as ASPasswordCredential:
            
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            
            print(username)
            print(password)
            
        default:
            break
        }
    }
    
    func saveDataOnKeyChain(isDataStore: Bool, appleIDCredential:ASAuthorizationAppleIDCredential) {
           if !isDataStore {
               // Create an account in your system.
               let userIdentifier = appleIDCredential.user
               let surname = appleIDCredential.fullName?.familyName ?? ""
               let firstname = appleIDCredential.fullName?.givenName ?? ""
               let emailAddress = appleIDCredential.email
               
               var fullName = ""
               if let fName = appleIDCredential.fullName?.givenName, let lName = appleIDCredential.fullName?.familyName {
                   fullName = "\(fName) \(lName)"
               } else {
                    if let fName = appleIDCredential.fullName?.givenName {
                        fullName = fName
                    }
               }
               
               var dict = [String: String]()
               dict["fullname"] = fullName
               dict["surname"] = surname
               dict["firstname"] = firstname
               dict["email"] = emailAddress
               dict["userIdentifier"] = userIdentifier
               var socialId = appleIDCredential.user
               socialId = socialId.replacingOccurrences(of: ".", with: "")
              
              // For the purpose of this demo app, store the `userIdentifier` in the keychain.
               self.saveUserDataKeychain(dict)
               print("User id is \(userIdentifier) \n Full Name is \(String(describing: fullName)) \n Email id is \(String(describing: emailAddress))")

               let socialUser = SocialLoginUser(
                 id: socialId,
                 name: fullName,
                 username: fullName,
                 firstName: firstname,
                 lastName: surname,
                 email: emailAddress,
                 profileImageURL: "",
                 authToken: ""
               )
               handler?(.success(socialUser))
           } else {
               let userData = KeychainItem.getUserInfo
               do {
                   let JSONData = userData.data(using: .utf8)!
                   if let jsonResult = try JSONSerialization.jsonObject(with: JSONData, options: .mutableLeaves) as? [String: String] {
                       var socialId = ""
                       if let userIdentifier = jsonResult["userIdentifier"] {
                           socialId = userIdentifier
                           socialId = socialId.replacingOccurrences(of: ".", with: "")
                       }
                       
                       var fullName = ""
                       if let fName = jsonResult["fullname"] {
                        fullName = fName
                       }

                       var email = ""
                       if let ema = jsonResult["email"] {
                           email = ema
                       }
                       var firstName = ""
                       if let fName = jsonResult["firstname"] {
                         firstName = fName
                       }
                     
                       var lastName = ""
                       if let lName = jsonResult["surname"] {
                          lastName = lName
                       }
                       
                       let socialUser = SocialLoginUser(
                         id: socialId,
                         name: fullName,
                         username: fullName,
                         firstName: firstName,
                         lastName: lastName,
                         email: email,
                         profileImageURL: "",
                         authToken: ""
                       )
                       handler?(.success(socialUser))
                   }

               } catch {
                   print("Error")
               }
           }
       }
    
    private func saveUserInKeychain(_ userIdentifier: String) {
        do {
            try KeychainItem(service: "com.mjlob.app", account: "userIdentifier").saveItem(userIdentifier)
        } catch {
            print("Unable to save userIdentifier to keychain.")
        }
    }
    
    private func saveUserDataKeychain(_ userInfo: [String: String]) {
           do {
               try KeychainItem(service: "com.mjlob.app", account: "userIdentifier").saveItemUserData(userInfo)
           } catch {
               print("Unable to save userIdentifier to keychain.")
           }
    }
}
