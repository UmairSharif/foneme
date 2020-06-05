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
import UserNotifications
import SystemConfiguration
import IQKeyboardManagerSwift
import Branch
import SendBirdSDK

protocol PushKitEventDelegate: AnyObject {
    func credentialsUpdated(credentials: PKPushCredentials) -> Void
    func credentialsInvalidated() -> Void
    func incomingPushReceived(payload: PKPushPayload) -> Void
    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void) -> Void
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var userInfo : [AnyHashable : Any]?
    let gcmMessageIDKey = "gcm.message_id"
    var launchFromPushNotific = false
    var provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "Fone"))
    var pushKitEventDelegate: PushKitEventDelegate?
    var voipRegistry : PKPushRegistry?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Voip Push Call Registry
       // self.voipRegistration()
        
        //Config Firebase
        FirebaseApp.configure()
        Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
             // do stuff with deep link data (nav to page, display content, etc)
            if let params = params as? [String: AnyObject] {
                if let foneId = params["ID"] as? String {
                    self.getUserDetail(foneId)
                }
            }
            
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        SBDMain.initWithApplicationId(APP_ID)

        let isLogin = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        if isLogin
        {
            //Call Local Contacts Function
            LocalContactHandler.instance.getContacts()
            
            let tabBarVC = UIStoryboard().loadTabBarController()
            appDeleg.window?.rootViewController = tabBarVC
            appDeleg.window?.makeKeyAndVisible()
            
            var USER_ID : String?
            var USER_NAME : String?
            
            if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                print(userProfileData)
                if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                    USER_ID = user.mobile
                    USER_NAME = user.name
                    
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
        
        return true
    }
    
    func voipRegistration() {
           let mainQueue = DispatchQueue.main
           // Create a push registry object
           self.voipRegistry = PKPushRegistry(queue: mainQueue)
           // Set the registry's delegate to self
        self.voipRegistry?.delegate = self
           // Set the push type to VoIP
        self.voipRegistry?.desiredPushTypes = [PKPushType.voIP]
       }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        Branch.getInstance().continue(userActivity)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Branch.getInstance().application(app, open: url, options: options)
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
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print(userInfo)
        
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
        
        completionHandler(UIBackgroundFetchResult.newData)
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
    
    func getUserDetail(_ foneId: String)
    {
        if let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String, loginToken.isEmpty == false {
            
            let params = ["DeviceToken": foneId] as [String:Any]
            print("params: \(params)")
                
            var headers = [String:String]()
            headers = ["Content-Type": "application/json",
                           "Authorization" : "bearer " + loginToken]
            
            ServerCall.makeCallWitoutFile(getProfileUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
                
                if let json = response {
                    
                    let statusCode = json["StatusCode"].string ?? ""
                    if statusCode == "200" {
                        if let profileData = json["UserProfileData"].dictionary {
                            if let mobileNumber = profileData["PhoneNumber"]?.string {
                                let vc = UIStoryboard().loadVideoCallVC()
                                vc.recieverNumber = mobileNumber
                                vc.userImage = profileData["ImageUrl"]?.string ?? ""
                                topViewController()?.present(vc, animated: true, completion: {
                                })
                            }
                        }
                    }
                }
            }
        }
    }
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    

    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        userInfo = notification.request.content.userInfo
        
        
        if let messageID = userInfo![gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        topViewController()?.seralizeNotificationResult()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        userInfo = response.notification.request.content.userInfo
        // Print message ID.
        
        
        if let messageID = userInfo![gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
    
        topViewController()?.seralizeNotificationResult()
        
        completionHandler()
    }
    
}

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        //HKCallHandler.shared.fcmToken = fcmToken
        UserDefaults.standard.set(fcmToken, forKey: Key_FCM_token)
        UserDefaults.standard.synchronize()
        let dataDict:[String: String] = ["token": fcmToken]
        
    
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    // [END refresh_token]
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}


extension AppDelegate: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
//        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
//        NSLog("voip token: \(token)")
        
        let tokens = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print("voip token: \(tokens)")
        
        UserDefaults.standard.set(tokens, forKey: "VoipToken")
        UserDefaults.standard.synchronize()
    }

    func pushRegistry(registry: PKPushRegistry!, didUpdatePushCredentials credentials: PKPushCredentials!, forType type: String!) {

        //print out the VoIP token. We will use this to test the notification.
        let token = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        NSLog("voip token: \(token)")
    
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        
        
        let payloadDict = payload.dictionaryPayload["aps"] as? [AnyHashable : Any]
        
        let receiverId = payloadDict?["ReceiverId"] as? AnyHashable
        let notificationType = payloadDict?["NotificationType"] as? AnyHashable
        let callStatusLogId = payloadDict?["CallLogStatusId"] as? AnyHashable
        let callType = payloadDict?["CallType"] as? AnyHashable
        let dialerNumber = payloadDict?["DialerNumber"] as? AnyHashable
        let status = payloadDict?["Status"] as? AnyHashable
        let callerName = payloadDict?["CallerName"] as? AnyHashable
        let dialerId = payloadDict?["DialerId"] as? AnyHashable
        let receiverNumber = payloadDict?["ReceiverNumber"] as? AnyHashable
        let channelName = payloadDict?["ChannelName"] as? AnyHashable
        let callDate = payloadDict?["CallDate"] as? AnyHashable
        let dialerImageUrl = payloadDict?["DialerImageUrl"] as? AnyHashable
        _ = payloadDict?["alert"] as? AnyHashable
        _ = payloadDict?[AnyHashable("body")] as? AnyHashable
        _ = payloadDict?["title"] as? AnyHashable

        if type == .voIP
        {
            //present a local notifcation to visually see when we are recieving a VoIP Notification
            if UIApplication.shared.applicationState == UIApplication.State.background {
                
                if notificationType as? String == "CLLCN"
                        {
                           DispatchQueue.main.async {
                            
                            self.provider.setDelegate(self, queue: nil)
                            let update = CXCallUpdate()
                            update.remoteHandle = CXHandle(type: .phoneNumber, value: callerName as? String ?? "")
                            self.provider.reportNewIncomingCall(with: UUID(), update: update, completion: { error in })
                            
                            NotificationHandler.shared.receiverId = receiverId as? String
                            NotificationHandler.shared.notificationType = notificationType as? String
                            NotificationHandler.shared.callStatusLogId = callStatusLogId as? String
                            NotificationHandler.shared.callType = callType as? String
                            NotificationHandler.shared.dialerNumber = dialerNumber as? String
                            NotificationHandler.shared.status = status as? String
                            NotificationHandler.shared.dialerId = dialerId as? String
                            NotificationHandler.shared.receiverNumber = receiverNumber as? String
                            NotificationHandler.shared.channelName = channelName as? String
                            NotificationHandler.shared.callDate = callDate as? String
                            NotificationHandler.shared.dialerImageUrl = dialerImageUrl as? String
                            NotificationHandler.shared.callStatus = true
                            }
                        }
                    
                        else if notificationType as? String == "UNA"
                        {
                            topViewController()?.performsEndCallAction()
                            NotificationHandler.shared.callStatus = false
                        }
                            
                        else if notificationType as? String == "CE"
                        {

                            topViewController()?.performsEndCallAction()
                            NotificationHandler.shared.callStatus = false
                        }
                
            }
            if UIApplication.shared.applicationState == UIApplication.State.active {
                print("Active")
                
                if notificationType as? String == "CLLCN"
                {
                    DispatchQueue.main.async {
                        
                    self.provider.setDelegate(self, queue: nil)
                    let update = CXCallUpdate()
                    update.remoteHandle = CXHandle(type: .generic, value: callerName as? String ?? "")
                        self.provider.reportNewIncomingCall(with: UUID(), update: update, completion: { error in })
                    
                    NotificationHandler.shared.receiverId = receiverId as? String
                    NotificationHandler.shared.notificationType = notificationType as? String
                    NotificationHandler.shared.callStatusLogId = callStatusLogId as? String
                    NotificationHandler.shared.callType = callType as? String
                    NotificationHandler.shared.dialerNumber = dialerNumber as? String
                    NotificationHandler.shared.status = status as? String
                    NotificationHandler.shared.dialerId = dialerId as? String
                    NotificationHandler.shared.receiverNumber = receiverNumber as? String
                    NotificationHandler.shared.channelName = channelName as? String
                    NotificationHandler.shared.callDate = callDate as? String
                    NotificationHandler.shared.dialerImageUrl = dialerImageUrl as? String
                    NotificationHandler.shared.callStatus = true
                    }
                }
                else if notificationType as? String == "UNA"
                {
                    topViewController()?.performsEndCallAction()
                    NotificationHandler.shared.callStatus = false
                }
                    
                else if notificationType as? String == "CE"
                {

                    topViewController()?.performsEndCallAction()
                    NotificationHandler.shared.callStatus = false
                }
            }
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        
        print("token invalidated")
    }
}


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
