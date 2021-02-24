//
//  HKStoryboardExt.swift
//  Raven
//
//  Created by hassan qureshi on 9/4/18.
//  Copyright © 2018 mindslab. All rights reserved.
//

import UIKit


fileprivate enum Storyboard : String {
    case authentication = "Authentication"
    case home = "Home"
}


fileprivate extension UIStoryboard {
    
    func load(from Storyboard: Storyboard, _ identifier: String) -> UIViewController {
        let uiStoryboard = UIStoryboard.init(name: Storyboard.rawValue, bundle: nil)
        let vc = uiStoryboard.instantiateViewController(withIdentifier: identifier)
        return vc
    }
    
    func loadFromStoryBoard(_ type: Storyboard, _ identifier: String) -> UIViewController {
        let vc = load(from: type, identifier)
        return vc
    }
    
}

//  MARK:- Stories in Main Storyboard
extension UIStoryboard {
    
    ///***** Authentication Storyboard View Controllers *****///
    
    
    func loadLoginNavVC() -> UINavigationController
    {
        return self.loadFromStoryBoard(.authentication , "Nav") as! UINavigationController
    }
    
    func loadSignUpVC() -> SignUpVC
    {
        return self.loadFromStoryBoard(.authentication , "SignUpVC") as! SignUpVC
    }
    
    func loadCountryCodeVC() -> CountryCodeVC
    {
        return self.loadFromStoryBoard(.authentication , "CountryCodeVC") as! CountryCodeVC
    }
    
    func loadMobileVC() -> MobileVC
    {
        return self.loadFromStoryBoard(.authentication , "MobileVC") as! MobileVC
    }
    
    func loadVerificationVC() -> VerificationVC
    {
        return self.loadFromStoryBoard(.authentication , "VerificationVC") as! VerificationVC
    }
    
    func loadForgotPasswordVC() -> ForgotPasswordVC
    {
        return self.loadFromStoryBoard(.authentication , "ForgotPasswordVC") as! ForgotPasswordVC
    }
    
    func loadPolicyVC() -> PolicyVC
    {
        return self.loadFromStoryBoard(.authentication , "PolicyVC") as! PolicyVC
    }
     func loadAboutVC() -> AboutMeVC
    {
    return self.loadFromStoryBoard(.authentication , "AboutMeVC") as! AboutMeVC

    }
    
    
    //// ******* Home Storyboard ****** ////
    
    func loadTabBarController() -> UITabBarController {
        return self.loadFromStoryBoard(.home , "TabBar") as! UITabBarController
    }
    
    func loadNavBarVC() -> UINavigationController
    {
        return self.loadFromStoryBoard(.home , "NavBar") as! UINavigationController
    }
    
    func loadContactVC() -> ContactVC
    {
        return self.loadFromStoryBoard(.home , "ContactVC") as! ContactVC
    }
    
    func loadHelpVC() -> HelpVC
    {
        return self.loadFromStoryBoard(.home , "HelpVC") as! HelpVC
    }
    
    func loadPlanVC() -> PlanListVC {
           return self.loadFromStoryBoard(.home , "PlanListVC") as! PlanListVC
       }
    
    func loadEditProfileVC() -> EditProfileVC
    {
        return self.loadFromStoryBoard(.home , "EditProfileVC") as! EditProfileVC
    }
    func loadaboutProfileVC() -> AboutmeProfileVC
    {
        return self.loadFromStoryBoard(.home , "AboutmeProfileVC") as! AboutmeProfileVC
    }
    
    
    func loadCallVC() -> CallVC
    {
        return self.loadFromStoryBoard(.home , "CallVC") as! CallVC
    }
    
    func loadLocalContactVC() -> LocalContactVC
    {
        return self.loadFromStoryBoard(.home , "LocalContactVC") as! LocalContactVC
    }
    
    func loadVideoCallVC() -> VideoCallVC
    {
        NotificationHandler.setSharedNotificationsForOutgoingCall()
        return self.loadFromStoryBoard(.home , "VideoCallVC") as! VideoCallVC
    }
    
    func loadVoiceCallVC() -> VoiceCallVC
    {
        return self.loadFromStoryBoard(.home , "VoiceCallVC") as! VoiceCallVC
    }
    func loadUserDetailsVC() -> UserDetailsVC
    {
        return self.loadFromStoryBoard(.home , "UserDetailsVC") as! UserDetailsVC
    }
    
}
