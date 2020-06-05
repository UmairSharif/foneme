//
//  Enums.swift
//  RestaurantFinder
//
//  Created by Hamza on 10/16/18.
//  Copyright © 2018 mindslab. All rights reserved.
//

import Foundation

public enum Method : String {
    case GET = "GET"
    case PUT = "PUT"
    case POST = "POST"
    case DELETE = "DELETE"
}


public enum TabBarItems : Int {
    case HOME = 0
    case CALLS = 1
    case CONTACTS = 2
    case PROFILE = 3
}

public enum DEVICE : Int {
    case iPhone5S = 0
    case iPhone6S = 1
    case iPhoneX = 2
}


public enum ScrollDirection : Int {
    case None
    case Right
    case Left
    case Up
    case Down
    case Crazy
}


public enum UITabBarItem : Int {
    case RestauntantsTab = 0
    case OrdersHistoryTab = 1
    case ProfileTab = 2
}


public enum UserType : Int {
    case User = 1
    case Provider = 2
}
