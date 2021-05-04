//
//  AppDelegate.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import CallKit
import PushKit
import CoreData
import Firebase
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import SystemConfiguration
import IQKeyboardManagerSwift
import Branch
import SendBirdSDK
import AudioToolbox
import TwilioVideo
import Alamofire
import OneSignal
import SwiftyJSON

protocol PushKitEventDelegate: AnyObject {
    func credentialsUpdated(credentials: PKPushCredentials) -> Void
    func credentialsInvalidated() -> Void
    func incomingPushReceived(payload: PKPushPayload) -> Void
    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void) -> Void
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,BranchDelegate,CLLocationManagerDelegate, GroupChannelsUpdateListDelegate {
    
    var window: UIWindow?
    var userInfo : [AnyHashable : Any]?
    let gcmMessageIDKey = "gcm.message_id"
    var launchFromPushNotific = false
    
    var navigationController: UINavigationController?
    var audioDevice: DefaultAudioDevice = DefaultAudioDevice()
    var pushKitEventDelegate: PushKitEventDelegate?
    var voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
    let viewController = UIStoryboard.init(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "VideoCallVC") as! VideoCallVC
    var locManager = CLLocationManager()
    var changeLocAuthoriseStatus : ((CLAuthorizationStatus) -> ())?
    var updateLocBlock : ((CLLocation) -> ())?

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        OneSignal.setLogLevel(.LL_INFO, visualLevel: .LL_NONE)

          // OneSignal initialization NEW CODE : 16 JAN
          OneSignal.initWithLaunchOptions(launchOptions)
          OneSignal.setAppId(OneSignalId)
        
        //START OneSignal initialization code
     //   OLD ONE .......
/*        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false, kOSSettingsKeyInAppLaunchURL: false]
        
        // Replace 'YOUR_ONESIGNAL_APP_ID' with your OneSignal App ID.
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: OneSignalId,
                                        handleNotificationAction: nil,
                                        settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
 */
        OneSignal.consentGranted(true)
        // The promptForPushNotifications function code will show the iOS push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission (See step 6)
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
        })
        
        LocationAcess()
        // Voip Push Call Registry
        // self.voipRegistration()
        TwilioVideoSDK.audioDevice = self.audioDevice;
        self.pushKitEventDelegate = viewController
        initializePushKit()
        //Config Firebase
        FirebaseApp.configure()
        Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
            // do stuff with deep link data (nav to page, display content, etc)
            print(params ?? "");

            if let params = params as? [String: AnyObject] {
                
            if let GroupId = params["GroupnName"] as? String   {
                
                self.RedirectToGroup(GrpName: GroupId)
             }
            else if let GroupId = params["GroupName"] as? String   {
                self.RedirectToGroup(GrpName: GroupId)
             }
              else if let foneId = params["ID"] as? String {
                    if let topVC = topViewController() {
                        topVC.view.alpha = 0.2
                        topVC.view.sd_showActivityIndicatorView()
                        let vc = UIStoryboard().loadUserDetailsVC()
//                        vc.userDetails = userModel!
                        vc.FoneID = foneId
                        vc.isFromLink = true
                        vc.modalPresentationStyle = .overFullScreen
                        vc.modalTransitionStyle = .crossDissolve
                        topVC.present(vc, animated: false, completion: {
                            topVC.view.alpha = 1
                        })
                    }
                } else if let channelURL  = params["~channel"] as? String {
                    if channelURL.contains("sendbird_group_channel") {
                        //Group
                        if let topVC = topViewController() {
//                            topVC.view.alpha = 0.1
                        SBDGroupChannel.getWithUrl(channelURL) { (groupChannel, error) in
                            guard error == nil else {
                                // Error.
//                                topVC.view.alpha = 1
                                return
                            }
                            // TODO: Implement what is needed with the contents of the response in the groupChannel parameter.
                            
                            let vc = UIStoryboard(name: "GroupChannel", bundle: nil).instantiateViewController(withIdentifier: "GrouplChatViewController") as! GroupChannelChatViewController
                             vc.channel = groupChannel
                             vc.modalPresentationStyle = .overFullScreen
                            vc.modalTransitionStyle = .crossDissolve
                            let navCont = UINavigationController.init(rootViewController: vc)
                            topVC.present(navCont, animated: false, completion: {
//                                topVC.view.alpha = 1
                            })


                        }
                        }
                        
                      
                    } else {
                        //Open Channel
                        if let topVC = topViewController() {
//                            topVC.view.alpha = 0.1
                        SBDOpenChannel.getWithUrl(channelURL) { (groupChannel, error) in
                            guard error == nil else {
//                                topVC.view.alpha = 1
                                // Error.
                                return
                            }
                            // TODO: Implement what is needed with the contents of the response in the groupChannel parameter.
                            
                            let vc = UIStoryboard(name: "OpenChannel", bundle: nil).instantiateViewController(withIdentifier: "OpenChannelChatViewController") as! OpenChannelChatViewController
                             vc.channel = groupChannel
                             vc.modalPresentationStyle = .overFullScreen
                            vc.modalTransitionStyle = .crossDissolve
                            let navCont = UINavigationController.init(rootViewController: vc)
                            
                            topVC.present(navCont, animated: false, completion: {
                                topVC.view.alpha = 1
                            })
                        }
                        }
                    }
                    print(params);
                }
            }
            
        }
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
            var identifiers: [String] = []
            for notification:UNNotificationRequest in notificationRequests {
                if notification.identifier == "identifierCancel" {
                    identifiers.append(notification.identifier)
                }
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
        //NotificationHandler.shared.isCallNotificationHandled = true
        
        SBDMain.initWithApplicationId(APP_ID)
        SBDMain.add(self as SBDChannelDelegate, identifier: self.description)
        let isLogin = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        if isLogin {
            //Call Local Contacts Function
            LocalContactHandler.instance.getContacts()
            
//            let vc = UIStoryboard().loadAboutVC()
//            vc.Userid = self.userId ?? ""
//            self.navigationController?.pushViewController(vc, animated: true)
            
            
            
            let tabBarVC = UIStoryboard().loadTabBarController()
            appDeleg.window?.rootViewController = tabBarVC
            appDeleg.window?.makeKeyAndVisible()
            
            var USER_ID : String?
            var USER_NAME : String?
            
            if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                print(userProfileData)
                if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                    USER_ID = user.mobile ?? ""
                    USER_NAME = user.name ?? ""
                    
//                    let vc = UIStoryboard().loadAboutVC()
//                    vc.Userid = USER_ID ?? ""
//                    self.navigationController?.pushViewController(vc, animated: true)
                    
                    let userDefault = UserDefaults.standard
                    userDefault.setValue(USER_ID, forKey: "sendbird_user_id")
                    userDefault.setValue(USER_NAME, forKey: "sendbird_user_nickname")
                    
                    ConnectionManager.login(userId: USER_ID!, nickname: USER_NAME!) { user, error in
                        print(error ?? "not an error")
                        guard error == nil else {
                            //Utils.showAlertController(error: error as! SBDError, viewController: self)
                            return
                        }
                    }
                }
            }
        }
        else
        {
            let vc = UIStoryboard().loadLoginNavVC()
            appDeleg.window?.rootViewController = vc
            appDeleg.window?.makeKeyAndVisible()
        }
        
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = self
        
        Messaging.messaging().subscribe(toTopic: "CallConnect") { error in
            print("Subscribed to weather topic")
        }
        
        // [END set_messaging_delegate]
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
        
        self.registerForLocalNotifications()
        // [END register_for_notifications]
        
        
        if (launchOptions != nil)
        {
            //opened from a push notification when the app is closed
            if let userInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable : Any]
            {
                print("userInfo-> \(userInfo["aps"]!)")
                //write you push handle code here
                launchFromPushNotific = true
            }
            
        }
        
        //Application Setup
        configureApplicationSetup()
        
        navigationController = application.windows[0].rootViewController as? UINavigationController
        
        
        
        return true
    }
    
    
    func RedirectToGroup(GrpName:String)
    {
        let parameters = [
            "GroupName": GrpName
        ] as [String:Any]
        var  activity: UIActivityIndicatorView?
        // print("params: \(parameters)")
      if  let topVC = topViewController()
        {
         activity = UIActivityIndicatorView.init(frame: CGRect.init(x: topVC.view.frame.width/2 - 30, y: topVC.view.frame.height/2, width: 60, height: 60))
        activity?.style = .gray
//                            topVC.view.alpha = 0.8
        activity?.startAnimating()
        activity?.hidesWhenStopped = true
        topVC.view.addSubview(activity!)

        }
        var headers = [String:String]()
        headers = ["Content-Type": "application/json"]
      
        ServerCall.makeCallWitoutFile(SearchGroupbyName, params: parameters, type: Method.POST, currentView: nil, header: headers) { (response) in
            if let json = response {
                  debugPrint(json)
                
                let statusCode = json["StatusCode"].string ?? ""
                if let arr = json.dictionary
                {
                    if let vall = arr["GroupData"]?.array
                    {
                        
                        if  vall.count > 0
                        {
                            var channame = GrpName
                            var grouptype = "false"
                            if let chanel = vall[0].dictionary
                            {
                                channame = chanel["GroupID"]?.string ?? ""
                                grouptype = chanel["IsPublic"]?.string ?? ""
//                            channame =  GrpName //OXvlz0AVieb
                            }
                        if let topVC = topViewController() {
                            
                          
                            if grouptype != "False"{
                                var channel: SBDOpenChannel?

                                
                        SBDOpenChannel.getWithUrl(channame) { (groupChannel, error) in
                            guard error == nil else {
//                                topVC.view.alpha = 1
                                // Error.
                                return
                            }
                            channel = groupChannel
                            debugPrint("groupChannel",groupChannel?.name)
                            
                            topVC.view.alpha = 1.0
                            activity?.stopAnimating()
                            let vc = UIStoryboard(name: "OpenChannel", bundle: nil).instantiateViewController(withIdentifier: "OpenChannelChatViewController") as! OpenChannelChatViewController
                             vc.channel = channel
                            
                             vc.modalPresentationStyle = .overFullScreen
                            vc.modalTransitionStyle = .crossDissolve
                            let navCont = UINavigationController.init(rootViewController: vc)
                            
                            topVC.present(navCont, animated: false, completion: {
                                topVC.view.alpha = 1
                            })
                            
                        }}
                            else{
                                
                                var channel: SBDGroupChannel?
                                SBDGroupChannel.getWithUrl(channame) { (groupChannel, error) in
                                    guard error == nil else {
        //                                topVC.view.alpha = 1
                                        // Error.
                                        return
                                    }
                                    channel = groupChannel
                                    debugPrint("groupChannel",groupChannel?.name)
                                    topVC.view.alpha = 1.0
                                    activity?.stopAnimating()

                                    let vc = UIStoryboard(name: "GroupChannel", bundle: nil).instantiateViewController(withIdentifier: "GrouplChatViewController") as! GroupChannelChatViewController
                                     vc.channel = channel
                                    vc.isfromNotif = true
                                     vc.modalPresentationStyle = .overFullScreen
                                    vc.modalTransitionStyle = .crossDissolve
                                    let navCont = UINavigationController.init(rootViewController: vc)
                                    topVC.present(navCont, animated: false, completion: {
        //                                topVC.view.alpha = 1
                                    })
                                }
                            }
                            // TODO: Implement what is needed with the contents of the response in the groupChannel parameter.
                            

                        }
                        }
                        
                    }
                    }
                    
                
                if statusCode == "200" || statusCode == "201"
                {
                    
                }
                //Table View Reload
            }
        }
    
    }
    
    
    func initializePushKit() {
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
        
    }
    
    func voipRegistration() {
        let mainQueue = DispatchQueue.global()
        // Create a push registry object
        self.voipRegistry = PKPushRegistry(queue: mainQueue)
        // Set the registry's delegate to self
        //        self.voipRegistry?.delegate = self
        //        // Set the push type to VoIP
        //        self.voipRegistry?.desiredPushTypes = [PKPushType.voIP]
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        Branch.getInstance().continue(userActivity)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        Branch.getInstance().application(app, open: url, options: options)
    }
    //MARK:- LOCATION METHODS
    var isLocationPermissionGranted : Bool
    {
        guard CLLocationManager.locationServicesEnabled() else { return false }
        return [.authorizedAlways, .authorizedWhenInUse].contains(CLLocationManager.authorizationStatus())
    }
    
    var isUserDeniedLocation : Bool {
        guard CLLocationManager.locationServicesEnabled() else { return true }
        return [.denied, .restricted].contains(CLLocationManager.authorizationStatus())
    }
    
    //Get Location access
    func getLocationAccess() {
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locManager.requestWhenInUseAuthorization()
        locManager.startUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            updateLocBlock?(loc)
            //               GLBLocation = loc
            GLBLatitude = loc.coordinate.latitude
            GLBLongitude = loc.coordinate.longitude
            debugPrint("\n Current Location >>>>>>>",GLBLatitude , GLBLongitude)
            manager.stopUpdatingLocation()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.changeLocAuthoriseStatus?(status)
    }
    
    
    func LocationAcess()
    {
     if appDelegateShareInst.isUserDeniedLocation {
         DispatchQueue.main.async {
             let alertController = UIAlertController(title: nil, message: "Turn on Location Services to Allow Fone Messenger to Determine Your Location", preferredStyle: .alert)
             alertController.addAction(UIAlertAction(title: "Setting", style: .default, handler: { (action) in
                 DispatchQueue.main.async {
                     if let settingsUrl = URL(string: UIApplication.openSettingsURLString) , UIApplication.shared.canOpenURL(settingsUrl) {
                         UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                     }
                 }
             }))
             alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
             
            self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
         }
     } else {
         appDelegateShareInst.getLocationAccess()
     }
    }
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        var bgTask: UIBackgroundTaskIdentifier
        bgTask = UIBackgroundTaskIdentifier.invalid
        bgTask = application.beginBackgroundTask(withName: "MyTask", expirationHandler: {
            // Clean up any unfinished task business by marking where you
            // stopped or ending the task outright.
            application.endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskIdentifier.invalid
        })
        
        // Start the long-running task and return immediately.
        DispatchQueue.global(qos: .default).async(execute: {
            
            // Do the work associated with the task, preferably in chunks.
            
            application.endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskIdentifier.invalid
        })
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        //            topViewController()?.testingCall()
        //        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //fireRepeatingNotification()
    }
    
    func fireRepeatingNotification(counter  : Int) {
        
        if counter > 15{
            return
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            
            UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
                var identifiers: [String] = []
                for notification:UNNotificationRequest in notificationRequests {
                    if notification.identifier == "identifierCancel" {
                        identifiers.append(notification.identifier)
                    }
                }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let content = UNMutableNotificationContent()
            
            if let callType = self.userInfo?["CallType"] as? String {
                var callTypeString = "video"
                if callType == "AD" {
                    callTypeString = "audio"
                }
                callTypeString += "  call"
                var notificationTitle = "You are receiving " + (callType == "AD" ? "an " :  "a ") + callTypeString
                if let dialerFoneId = self.userInfo?["DialerFoneID"] as? String {
                    notificationTitle += (" from " + dialerFoneId)
                }else {
                    notificationTitle += (" from someone")
                }
                content.title = notificationTitle
                content.body = "Tap to connect"
                content.categoryIdentifier = "ROOM_INVITATION"
                content.userInfo = self.userInfo ?? [ : ]
                //content.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: 1.0)
                let identifier = "identifierCancel"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { (error) in
                    if let theError = error {
                        print("Error posting local notification \(theError)")
                    }
                }
                AudioServicesPlaySystemSound(1003);
                self.fireRepeatingNotification(counter: counter + 1)
            }
            //DialerFoneID, RecieverFoneID
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Fone")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        
        if let push_type = userInfo[AnyHashable("push_type")] as? String {
            print(push_type)
          
        }
        if let push_type = userInfo[AnyHashable("aps")] as? String {
            print(push_type)
        }
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print(userInfo)
        if let sendbirdDict = userInfo["sendbird"] as? [String:Any] {
            if let channelDict  = sendbirdDict["channel"] as? [String:Any] {
                
            }
        }
        //        if UIApplication.shared.applicationState == UIApplication.State.background {
        //
        //            // Print full message.
        //            print(userInfo)
        //            self.userInfo = userInfo
        //            topViewController()?.seralizeNotificationResult()
        //        }
        //         if UIApplication.shared.applicationState == UIApplication.State.active {
        //
        //            // Print full message.
        //            print(userInfo)
        //            self.userInfo = userInfo
        //            topViewController()?.seralizeNotificationResult()
        //        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
        
        //        if UIApplication.shared.applicationState == UIApplication.State.background {
        //            self.userInfo = userInfo
        //            topViewController()?.seralizeNotificationResult()
        //            completionHandler(UIBackgroundFetchResult.newData)
        //        }
        //         if UIApplication.shared.applicationState == UIApplication.State.active {
        //            self.userInfo = userInfo
        //            topViewController()?.seralizeNotificationResult()
        //            completionHandler(UIBackgroundFetchResult.newData)
        //        }
        
        //NotificationHandler.shared.isCallNotificationHandled = false
        
        self.userInfo = userInfo
        topViewController()?.seralizeNotificationResult()
        //fireRepeatingNotification(counter: 0)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 20) {
            completionHandler(UIBackgroundFetchResult.newData)
        }
        
    }
    
    // [END receive_message]
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs token: \(token)")
        SBDMain.registerDevicePushToken(deviceToken, unique: true, completionHandler: { (status, error) in
            if error == nil {
                if status == SBDPushTokenRegistrationStatus.pending {
                    // A device token is pending.
                    print(status)
                }
                else {
                    // A device token is successfully registered.
                    print(status)
                }
            }
            else {
                // Registration failure.
                print(status)
            }
        })
    }
    
    //  MARK:- Configuration
    func configureApplicationSetup(){
        
        //IQKeyboard Setup
        IQKeyboardSetup()
    }
    
    func IQKeyboardSetup(){
        
        //IQKeyboard Manager
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableDebugging = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        
    }
    
    
    
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {

}

extension AppDelegate : SBDChannelDelegate {
    func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
        let topViewController = UIViewController.currentViewController()
        if topViewController is GroupChannelsViewController {
            return
        }
        
        if let vc = topViewController as? GroupChannelChatViewController {
            if vc.channel?.channelUrl == sender.channelUrl {
                return
            }
        }
        guard let groupChannel = sender as? SBDGroupChannel else { return }
        
        let pushOption = groupChannel.myPushTriggerOption
        
        switch pushOption {
        case .all, .default, .mentionOnly:
            break
        case .off:
            return
        @unknown default:
            return()
        }
        var title = ""
        var body = ""
        var type = ""
        var customType = ""
        if message is SBDUserMessage {
            let userMessage = message as! SBDUserMessage
            let sender = userMessage.sender
            
            type = "MESG"
            body = String(format: "%@: %@", (sender?.nickname)!, userMessage.message ?? "")
            customType = userMessage.customType!
        }
        else if message is SBDFileMessage {
            let fileMessage = message as! SBDFileMessage
            let sender = fileMessage.sender
            
            if fileMessage.type.hasPrefix("image") {
                body = String(format: "%@: (Image)", (sender?.nickname)!)
            }
            else if fileMessage.type.hasPrefix("video") {
                body = String(format: "%@: (Video)", (sender?.nickname)!)
            }
            else if fileMessage.type.hasPrefix("audio") {
                body = String(format: "%@: (Audio)", (sender?.nickname)!)
            }
            else {
                body = String(format: "%@: (File)", sender!.nickname!)
            }
        }
        else if message is SBDAdminMessage {
            let adminMessage = message as! SBDAdminMessage
            
            title = ""
            body = adminMessage.message ?? ""
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "SENDBIRD_NEW_MESSAGE"
        content.userInfo = [
            "sendbird": [
                "type": type,
                "custom_type": customType,
                "channel": [
                    "channel_url": sender.channelUrl
                ],
                "data": "",
            ],
        ]
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: String(format: "%@_%@", content.categoryIdentifier, sender.channelUrl), content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            if error != nil {
                
            }
        }
    }
}



extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken)")
        
        //HKCallHandler.shared.fcmToken = fcmToken
        UserDefaults.standard.set(fcmToken, forKey: Key_FCM_token)
        UserDefaults.standard.synchronize()
        if let strval = fcmToken {
        let dataDict:[String: String] = ["token": strval]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)

        }
        self.updateFCMDeviceToken(token: fcmToken ?? "")
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    func updateFCMDeviceToken(token : String){
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                
                let parameters: Parameters = [
                    "UserGuid": user.userId ?? "",
                    "Data": token
                ] as [String : Any]
                let header = ["Content-Type":"application/json",
                              "charset":"utf-8"]
                Alamofire.request(changeuserdevicetoken, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: header)
                    .validate()
                    .responseString { (response) in
                        if response.error != nil {
                            print(response.error?.localizedDescription ?? "Request Error")
                            return
                        }else{
                            do{
                                let jsonData = try JSON(data: response.data!)
                                print(jsonData)
                                
                            }
                            catch{
                                print(error.localizedDescription )
                            }
                        }
                }
            }
        }
    }
    
}


/// Mark :- MyCode
extension AppDelegate : PKPushRegistryDelegate {
    // MARK: PKPushRegistryDelegate
    
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print("pushRegistry:didUpdatePushCredentials:forType:")
        
        let deviceToken = credentials.token.reduce("", {$0 + String(format: "%02X", $1) })
        print("\(#function) token is: \(deviceToken)")
        self.registerVOIPToken(voipToken: deviceToken, credentials: credentials)
    }
    
    func registerVOIPToken(voipToken:String , credentials: PKPushCredentials) {
        
        let parameters: Parameters = [
            "app_id": OneSignalId,
            "identifier": voipToken,
            "device_type":"0",
            //"test_type":"1"
        ]
        let header = ["Content-Type":"application/json",
                      "charset":"utf-8"]
        Alamofire.request(oneSignalRegisterVOIP, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: header)
            .validate()
            .responseString { (response) in
                if response.error != nil {
                    print(response.error?.localizedDescription ?? "Request Error")
                    return
                }else{
                    do{
                        let jsonData = try JSON(data: response.data!)
                        print(jsonData)
                        let success = jsonData["success"].boolValue
                        if success {
                            let id = jsonData["id"].stringValue
                            if let delegate = self.pushKitEventDelegate {
                                delegate.credentialsUpdated(credentials: credentials)
                            }
                            self.updateVoipDeviceToken(token: id)
                        }
                    }
                    catch{
                        print(error.localizedDescription )
                    }
                }
        }
    }
    
    func updateVoipDeviceToken(token : String){
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                
                let parameters: Parameters = [
                    "UserGuid": user.userId ?? "",
                    "Data": token
                ] as [String : Any]
                let header = ["Content-Type":"application/json",
                              "charset":"utf-8"]
                Alamofire.request(changeuservoiptoken, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: header)
                    .validate()
                    .responseString { (response) in
                        if response.error != nil {
                            print(response.error?.localizedDescription ?? "Request Error")
                            return
                        }else{
                            do{
                                let jsonData = try JSON(data: response.data!)
                                print(jsonData)
                                
                            }
                            catch{
                                print(error.localizedDescription )
                            }
                        }
                }
            }
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry:didInvalidatePushTokenForType:")
        
        if let delegate = self.pushKitEventDelegate {
            delegate.credentialsInvalidated()
        }
    }
    
    /**
     * Try using the `pushRegistry:didReceiveIncomingPushWithPayload:forType:withCompletionHandler:` method if
     * your application is targeting iOS 11. According to the docs, this delegate method is deprecated by Apple.
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        print("pushRegistry:didReceiveIncomingPushWithPayload:forType:")
        
        if let topVC = topViewController() {
            if topVC != viewController {
                topVC.present(viewController, animated: true) {
                    self.viewController.loadViewIfNeeded()
                    
                }
                if let delegate = self.pushKitEventDelegate {
                    delegate.incomingPushReceived(payload: payload)
                }
            }
        }
        
    }
    
    /**
     * This delegate method is available on iOS 11 and above. Call the completion handler once the
     * notification payload is passed to the `TwilioVoice.handleNotification()` method.
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        
        if let topVC = topViewController() {
            if topVC != viewController {
                topVC.present(viewController, animated: true) {
                    self.viewController.loadViewIfNeeded()
                    
                }
                if let delegate = self.pushKitEventDelegate {
                    delegate.incomingPushReceived(payload: payload, completion: completion)
                }
                if let version = Float(UIDevice.current.systemVersion), version >= 13.0 {
                    /**
                     * The Voice SDK processes the call notification and returns the call invite synchronously. Report the incoming call to
                     * CallKit and fulfill the completion before exiting this callback method.
                     */
                    
                    
                    completion()
                    
                }
            }
            
        }
        
    }
}



/*
 
 
 extension AppDelegate : CXProviderDelegate{
 
 public func providerDidReset(_ provider: CXProvider) {
 
 }
 
 public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
 
 if UIApplication.shared.applicationState == UIApplication.State.background {
 
 topViewController()?.navigateToCallScreen()
 //AudioCallHandler.instance.startFunc()
 }
 else //if UIApplication.shared.applicationState == UIApplication.State.active
 {
 topViewController()?.navigateToCallScreen()
 }
 action.fulfill()
 }
 
 public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
 
 DispatchQueue.main.async {
 
 if NotificationHandler.shared.callStatus ?? false
 {
 topViewController()?.sendMissedCallNotificationAPI()
 }
 action.fulfill()
 
 }
 }
 }
 */
