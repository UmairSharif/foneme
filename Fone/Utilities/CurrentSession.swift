//
//  CurrentSession.swift
//  Fone
//
//  Created by Thu Le on 10/08/2021.
//  Copyright © 2021 Fone.Me. All rights reserved.
//

import Foundation
import SwiftyJSON

final class CurrentSession: NSObject {
    static let shared = CurrentSession()
    
    var accessToken: String? {
        get {
            return UserDefaults.standard.string(forKey: "AccessToken")
        }
        set (value) {
            if let value = value {
                UserDefaults.standard.setValue(value, forKey: "AccessToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "AccessToken")
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    var user: User? {
        get {
            if let data = UserDefaults.standard.object(forKey: key_User_Profile) as? Data,
               let storedUser = try? PropertyListDecoder().decode(User.self, from: data) {
                return storedUser
            }
            return nil
        }
        
        set(value) {
            if let value = value {
                if let data = try? PropertyListEncoder().encode(value) {
                    UserDefaults.standard.set(data, forKey: key_User_Profile)
                }
            } else {
                UserDefaults.standard.removeObject(forKey: key_User_Profile)
            }
            UserDefaults.standard.synchronize()
            
        }
    }
    
    private (set) var friends: [FriendList] = []
    
    private override init() {
        super.init()
        loadFriendsFromCaches()
    }
    
    private func loadFriendsFromCaches() {
        guard let contactData = UserDefaults.standard.object(forKey: "Contacts") as? Data else {
            return
        }
        guard let contacts = try? PropertyListDecoder().decode([JSON].self, from: contactData) else {
            return
        }
        friends.removeAll()
        
        contacts.forEach { contact in
            let dict = contact.dictionary
            let number = dict?["ContactsNumber"]?.string ?? ""
            let name = dict?["ContactsName"]?.string ?? ""
            let userImage = dict?["Image"]?.string ?? ""
            let ContactsCnic = dict?["ContactsCnic"]?.string ?? ""
            let userid = dict?["ContactsVT"]?.string ?? ""
            friends.append(FriendList(name: name, number: number, userImage: userImage, ContactsCnic: ContactsCnic, userId: userid))
        }
    }
    
    func storeFriends(friends: [JSON]) {
        UserDefaults.standard.set(try? PropertyListEncoder().encode(friends), forKey: "Contacts")
        UserDefaults.standard.synchronize()
        
        loadFriendsFromCaches()
    }
}
