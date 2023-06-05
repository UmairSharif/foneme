//
//  SocialLoginUser.swift
//
//

import Foundation

struct SocialLoginUser {
  
  var id: String!
  var name: String?
  var username: String?
  var firstName: String?
  var lastName: String?
  var email: String?
  var profileImageURL: String?
  var authToken: String!
  
  init(
    id: String,
    name: String?,
    username: String?,
    firstName: String?,
    lastName: String?,
    email: String?,
    profileImageURL: String?,
    authToken: String
  ) {
    
    self.id = id
    self.name = name
    self.username = username
    self.firstName = firstName
    self.lastName = lastName
    self.email = email
    self.profileImageURL = profileImageURL
    self.authToken = authToken
  }
}

extension SocialLoginUser {
  
  func getName() -> String {
    if let value = name, !value.isEmpty {
      return value
    } else {
      return "User" + String.randomString(length: 4)
    }
  }
}

extension String {
  
  static func randomString(length: Int) -> String {
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)
    
    var randomString = ""
    
    for _ in 0 ..< length {
      let rand = arc4random_uniform(len)
      var nextChar = letters.character(at: Int(rand))
      randomString += NSString(characters: &nextChar, length: 1) as String
    }
    
    return randomString
  }
}

extension NSError {
  
  static func error(code: Int = 0, localizedDescription: String?) -> NSError {
    return NSError(
      domain: Bundle.main.bundleIdentifier!,
      code: code,
      userInfo: [NSLocalizedDescriptionKey: localizedDescription ?? ""]
    )
  }
}
