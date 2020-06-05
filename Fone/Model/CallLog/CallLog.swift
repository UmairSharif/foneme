//
//  CallLog.swift
//  Fone
//
//  Created by Bester on 10/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import Foundation

class CallLog: NSObject {
    
    var number : String?
    var userImage : String?
    var status : String?
    var dateTime : String?
    var name : String?
    
    init(number : String,userImage : String,status : String,dateTime : String,name: String) {
        
        self.number = number
        self.userImage = userImage
        self.status = status
        self.dateTime = dateTime
        self.name = name
    }
}
