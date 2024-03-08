//
//  RCValuesHandler.swift
//  Fone
//
//  Created by Shahrukh on 06/03/2024.
//  Copyright © 2024 Fone.Me. All rights reserved.
//

import Foundation
import Firebase
import FirebaseRemoteConfig

enum RCValueKey: String {
  case sendbirdAppID = "SENDBIRD_APP_ID"
}

class RCValuesHandler {
    
    static let sharedInstance = RCValuesHandler()
    
    private init() {
        loadDefaultValues()
        fetchCloudValues()
    }
    
    func loadDefaultValues() {
        let appDefaults: [String: Any?] = [
            RCValueKey.sendbirdAppID.rawValue: "6ECF7B6B-73F7-4E84-90C1-2A77919C5B78"
        ]
        RemoteConfig.remoteConfig().setDefaults(appDefaults as? [String: NSObject])
    }
    
    func configureSettings() {
        let settings = RemoteConfigSettings()
        // set fetch interval to 12 hours
        settings.minimumFetchInterval = 43200
        RemoteConfig.remoteConfig().configSettings = settings
    }
    
    func fetchCloudValues() {
        
        configureSettings()
        
        RemoteConfig.remoteConfig().fetch { _, error in
            if let error = error {
                print("Uh-oh. Got an error fetching remote values \(error)")
                return
            }
            
            RemoteConfig.remoteConfig().activate { _, _ in
                print("Retrieved values from the cloud!")
            }
        }
    }
    
    func string(forKey key: RCValueKey) -> String {
      RemoteConfig.remoteConfig()[key.rawValue].stringValue ?? ""
    }

}
