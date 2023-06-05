//
//  SocialLoginManager.swift
//
//

import Foundation
import UIKit.UIApplication
import FBSDKCoreKit

typealias SocialLoginResultHandler = (Result<SocialLoginUser, Error>) -> Void

struct SocialLoginConfiguration {
  
  static var appDisplayName = "FoneMe"
  
  struct Google {
    static var OAuthClientID: String = "147877945888-49mgflgtsjf2rq1u7gqva17ok7ma8oah.apps.googleusercontent.com"
  }
  
  struct Facebook {
    static var AppId: String = "1920619354936594"
  }
}

final class SocialLoginManager {
  
  var facebookAppId = SocialLoginConfiguration.Facebook.AppId
  var appDisplayName = SocialLoginConfiguration.appDisplayName
  
  enum Provider: String {
    case facebook, google, apple
    
    var name: String {
        return self.rawValue.capitalized
    }
  }
  
  static let shared = SocialLoginManager()
  
  func initialize() {
    //GoogleLogin.shared.initialize()
    
   // Settings.shared.appID = facebookAppId
    //Settings.shared.displayName = appDisplayName
  }
  
  func login(
    with provider: Provider,
    presenter: UIViewController,
    _ completion: @escaping SocialLoginResultHandler
  ) {
    switch provider {
    case .facebook:
      FBLogin
        .shared
        .login(
          viewController: presenter,
          completion: completion
        )
      
    case .google:
      GoogleLogin
        .shared
        .login(
          viewController: presenter,
          completion: completion
        )
      
    case .apple:
      AppleSignIn
        .shared
        .login(
        presenter,
        completion: completion
      )
    }
  }
  
  func logOut() {
    FBLogin.shared.logOut()
    GoogleLogin.shared.logOut()
  }
  
  func logOut(with provider: Provider) {
    switch provider {
    case .facebook:
      FBLogin.shared.logOut()
    
    case .google:
      GoogleLogin.shared.logOut()
      
    case .apple:
      break
    }
  }
}

// MARK: - Application delegate (handling)

extension SocialLoginManager {
  
  @discardableResult
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }
  
  @discardableResult
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if url.scheme == "fb" + facebookAppId {
      ApplicationDelegate.shared.application(
        app,
        open: url,
        sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
        annotation: options[UIApplication.OpenURLOptionsKey.annotation]
      )
    }
    
    return false
  }
}


