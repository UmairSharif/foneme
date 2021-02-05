//
//  Extensions.swift
//  Hammad Khan
//
//  Created by Ali rafiq on 16/05/2017.
//  Copyright © 2017 Ali. All rights reserved.
//


import UIKit
//import GoogleMobileAds
import Alamofire
import SwiftyJSON

protocol FullScreenAdsDelegate: class {
    func fullscreenAdLoaded()
    func fullscreenAdClosed()
}

public typealias isCompletion = (_ isCompleted: Bool?) -> Void

/// separate class for google sign-in methods
class FullScreenAdManager: NSObject {
    
    // MARK: - Properties
    
  /*  var onadLoaded: isCompletion?
    var onadDismissed: isCompletion?
    var interstitialAd: GADInterstitial?
    
    func createAndLoadInterstitial() {

        
        interstitialAd = GADInterstitial(adUnitID: "ca-app-pub-0169736027593374/6775235379")
        interstitialAd?.delegate = self
        interstitialAd?.load(GADRequest())
    }
    
}

// MARK: - GIDSignInDelegate methods
extension FullScreenAdManager: GADInterstitialDelegate {
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        if let onadDismissed = self.onadDismissed {
            onadDismissed(true)
        }
    }
    
    /// Tells the delegate an ad request succeeded.
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("interstitialDidReceiveAd")
        if let onadLoaded = self.onadLoaded {
            onadLoaded(true)
        }
    }
    
    /// Tells the delegate an ad request failed.
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
        if let onadDismissed = self.onadDismissed {
            onadDismissed(true)
        }
    }
    
    /// Tells the delegate that an interstitial will be presented.
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        print("interstitialWillPresentScreen")
    }
    
    /// Tells the delegate the interstitial is to be animated off the screen.
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        print("interstitialWillDismissScreen")
    }
    
    /// Tells the delegate the interstitial had been animated off the screen.
    //    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
    //      print("interstitialDidDismissScreen")
    //    }
    
    /// Tells the delegate that a user click will open another app
    /// (such as the App Store), backgrounding the current app.
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print("interstitialWillLeaveApplication")
    }*/
}

func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }
    
    if ((cString.count) != 6) {
        return UIColor.gray
    }
    
    var rgbValue:UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)
    
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

//  MARK:- UIVIEW EXT
extension UIView {
    
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            if self is UIImageView {
                layer.masksToBounds = true
            }
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
}


extension UITextField {
    
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:[NSAttributedString.Key.foregroundColor: newValue!])
        }
    }
    
}


//  MARK:- DATA EXT
extension Data {
    init(reading input: InputStream) {
        self.init()
        input.open()
        
        let bufferSize = 1036
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            self.append(buffer, count: read)
        }
        
        input.close()
    }
    
}


//  MARK:- UICOLOR EXT
extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

//  MARK:- STRING EXT
extension String {
    
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
    
    func isValidPasswordWithLength(length: Int) -> Bool {
        return (self.count > length) ? true : false
    }
    
    func isEmpty() -> Bool {
        return (self.count > 0) ? false : true
    }
    
}

extension UISearchBar {
    
    func getTextField() -> UITextField? { return value(forKey: "searchField") as? UITextField }
    func set(textColor: UIColor) { if let textField = getTextField() { textField.textColor = textColor } }
    func setPlaceholder(textColor: UIColor) { getTextField()?.setPlaceholder(textColor: textColor) }
    func setClearButton(color: UIColor) { getTextField()?.setClearButton(color: color) }
    
    func setTextField(color: UIColor) {
        guard let textField = getTextField() else { return }
        switch searchBarStyle {
        case .minimal:
            textField.layer.backgroundColor = color.cgColor
            textField.layer.cornerRadius = 6
        case .prominent, .default: textField.backgroundColor = color
        @unknown default: break
        }
    }
    
    func setSearchImage(color: UIColor) {
        guard let imageView = getTextField()?.leftView as? UIImageView else { return }
        imageView.tintColor = color
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
    }
}

private extension UITextField {
    
    private class Label: UILabel {
        private var _textColor = UIColor.lightGray
        override var textColor: UIColor! {
            set { super.textColor = _textColor }
            get { return _textColor }
        }
        
        init(label: UILabel, textColor: UIColor = .lightGray) {
            _textColor = textColor
            super.init(frame: label.frame)
            self.text = label.text
            self.font = label.font
        }
        
        required init?(coder: NSCoder) { super.init(coder: coder) }
    }
    
    
    private class ClearButtonImage {
        static private var _image: UIImage?
        static private var semaphore = DispatchSemaphore(value: 1)
        static func getImage(closure: @escaping (UIImage?)->()) {
            DispatchQueue.global(qos: .userInteractive).async {
                semaphore.wait()
                DispatchQueue.main.async {
                    if let image = _image { closure(image); semaphore.signal(); return }
                    guard let window = UIApplication.shared.windows.first else { semaphore.signal(); return }
                    let searchBar = UISearchBar(frame: CGRect(x: 0, y: -200, width: UIScreen.main.bounds.width, height: 44))
                    window.rootViewController?.view.addSubview(searchBar)
                    searchBar.text = "txt"
                    searchBar.layoutIfNeeded()
                    _image = searchBar.getTextField()?.getClearButton()?.image(for: .normal)
                    closure(_image)
                    searchBar.removeFromSuperview()
                    semaphore.signal()
                }
            }
        }
    }
    
    func setClearButton(color: UIColor) {
        ClearButtonImage.getImage { [weak self] image in
            guard   let image = image,
                let button = self?.getClearButton() else { return }
            button.imageView?.tintColor = color
            button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    var placeholderLabel: UILabel? { return value(forKey: "placeholderLabel") as? UILabel }
    
    func setPlaceholder(textColor: UIColor) {
        guard let placeholderLabel = placeholderLabel else { return }
        let label = Label(label: placeholderLabel, textColor: textColor)
        setValue(label, forKey: "placeholderLabel")
    }
    
    func getClearButton() -> UIButton? { return value(forKey: "clearButton") as? UIButton }
}


extension UIViewController {
    func sendFCMPush(title : String, description : String , fcmToken : String , params : Parameters) {
        
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        
        var headers = [String:String]()
        headers = ["Content-Type": "application/json",
                   "Authorization" : "bearer " + loginToken!]
        let params = [
            "Title": title,
            "Desc":description,
            "FcmToken":fcmToken,
            "Data": params ] as [String : Any]
        Alamofire.request(sendFcmOPt, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseJSON { (response) in
                if response.error != nil {
                    print(response.error?.localizedDescription ?? "Response Error" )
                }
                else {
                    do {
                        let jsonData = try JSON(data: response.data!)
                        print(jsonData)
                    }catch {
                        print(error.localizedDescription)
                    }
                }
        }
    }
    
    
    
    func showToast(controller: UIViewController, message : String, seconds: Double) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = UIColor.black
        alert.view.alpha = 0.6
        alert.view.layer.cornerRadius = 15
        
        controller.present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
        }
    }
    
    
    func getUserDetail(cnic foneId: String = "" ,friend friendId : String = "" ,_ completion : @escaping (_ model : UserDetailModel? , _ success : Bool) -> Void )
    {
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                
                if let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String, loginToken.isEmpty == false {
                    
                    let params = ["Me":user.userId ?? "",
                                  "Url":"",
                                  "Cnic" : foneId,
                                  "Friend":friendId] as [String:Any]
                    print("params: \(params)")
                    
                    var headers = [String:String]()
                    headers = ["Content-Type": "application/json",
                               "Authorization" : "bearer " + loginToken]
                    
                    ServerCall.makeCallWitoutFile(getProfileUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
                        
                        if let json = response {
                            print(json)
                            let statusCode = json["StatusCode"].string ?? ""
                            if statusCode == "200" {
                                let profileData = json["UserProfileData"]
                                var userModel = UserDetailModel(fromJson: profileData)
                                if foneId != "" {
                                    userModel.cnic = foneId
                                }
                                completion(userModel,true)
                            }
                            else{
                                completion(nil,false)
                            }
                        }else{
                            completion(nil,false)
                        }
                    }
                }
            }
        }
    }
    
    //MARK:- GET USER PROFILE
    func getUserProfile(cnic foneId: String = "" ,friend friendId : String = "" ,_ completion : @escaping (_ model : UserDetailModel? , _ success : Bool) -> Void )
    {
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                
                if let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String, loginToken.isEmpty == false {
                    
                    let params = ["Me":user.userId ?? "",
                                  "Url":"",
                                  "Cnic" : foneId,
                                  "Friend":friendId] as [String:Any]
                    print("params: \(params)")
                    
                    var headers = [String:String]()
                    headers = ["Content-Type": "application/json",
                               "Authorization" : "bearer " + loginToken]
                    
                    ServerCall.makeCallWitoutFile(GetUserProfile, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
                        
                        if let json = response {
                            print(json)
                            let statusCode = json["StatusCode"].string ?? ""
                            if statusCode == "200" {
                                let profileData = json["UserProfileData"]
                                var userModel = UserDetailModel(fromJson: profileData)
                                if foneId != "" {
                                    userModel.cnic = foneId
                                }
                                completion(userModel,true)
                            }
                            else{
                                completion(nil,false)
                            }
                        }else{
                            completion(nil,false)
                        }
                    }
                }
            }
        }
    }
    
    func addFirend( foneId: String , friendId : String,url : String ,_ completion : @escaping (_ model : UserDetailModel? , _ success : Bool) -> Void )
    {
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                
                if let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String, loginToken.isEmpty == false {
                    
                    let params = ["Me":user.userId ?? "",
                                  "Url":url,
                                  "Cnic" : foneId,
                                  "Friend":friendId] as [String:Any]
                    print("params: \(params)")
                    
                    var headers = [String:String]()
                    headers = ["Content-Type": "application/json",
                               "Authorization" : "bearer " + loginToken]
                    
                    ServerCall.makeCallWitoutFile(addMyFriend, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
                        
                        if let json = response {
                            print(json)
                            let statusCode = json["StatusCode"].string ?? "" //IsSuccessed
                            let IsSuccessed = json["IsSuccessed"].boolValue
                            
                            if statusCode == "200" {
                                let profileData = json["UserProfileData"]
                                var userModel = UserDetailModel(fromJson: profileData)
                                if foneId != "" {
                                    userModel.cnic = foneId
                                }
                                if IsSuccessed == false {
                                    completion(userModel,false)
                                    return
                                }
                                completion(userModel,true)
                            }
                            else{
                                completion(nil,false)
                                if let topVc = topViewController() {
                                    topVc.showAlert(response?.error?.localizedDescription ?? "JSON Error")
                                }
                            }
                        }else{
                            completion(nil,false)
                            if let topVc = topViewController() {
                                topVc.showAlert(response?.error?.localizedDescription ?? "Request Error")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func removeFirend( foneId: String , friendId : String,url : String ,_ completion : @escaping (_ model : UserDetailModel? , _ success : Bool) -> Void )
    {
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                
                if let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String, loginToken.isEmpty == false {
                    
                    let params = ["Me":user.userId ?? "",
                                  "Url":url,
                                  "Cnic" : foneId.isEmpty ? "null" : foneId ,
                                  "Friend":friendId] as [String:Any]
                    print("params: \(params)")
                    
                    var headers = [String:String]()
                    headers = ["Content-Type": "application/json",
                               "Authorization" : "bearer " + loginToken]
                    
                    ServerCall.makeCallWitoutFile(removeMyFriend, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
                        
                        if let json = response {
                            print(json)
                            let statusCode = json["StatusCode"].string ?? ""
                            if statusCode == "200" {
                                let profileData = json["UserProfileData"]
                                var userModel = UserDetailModel(fromJson: profileData)
                                if foneId != "" {
                                    userModel.cnic = foneId
                                }
                                completion(userModel,true)
                            }
                            else{
                                completion(nil,false)
                                if let topVc = topViewController() {
                                    topVc.showAlert(response?.error?.localizedDescription ?? "JSON Error")
                                }
                            }
                        }else{
                            completion(nil,false)
                            if let topVc = topViewController() {
                                topVc.showAlert(response?.error?.localizedDescription ?? "Request Error")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func searchFriend( byCnic: String ,_ completion : @escaping (_ model : [FriendList]? , _ success : Bool) -> Void )
    {
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String, loginToken.isEmpty == false {
                
                let params = ["byCnic":byCnic] as [String:Any]
                print("params: \(params)")
                
                var headers = [String:String]()
                headers = ["Content-Type": "application/json",
                           "Authorization" : "bearer " + loginToken]
                
                ServerCall.makeCallWitoutFile(searchUser, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
                    
                    if let json = response {
                        print(json)
                        let statusCode = json["StatusCode"].string ?? ""
                        if statusCode == "200" {
                            let profileData = json["Data"].array
                            var profilesList = [FriendList]()
                            if profileData != nil {
                                for json in profileData! {
                                    let number = json["PhoneNumber"].stringValue
                                    let name = json["Name"].stringValue
                                    let userImage = json["ImageUrl"].stringValue
                                    var ContactsCnic = json["Address"].stringValue
                                    let userId = json["UserId"].stringValue
                                    if ContactsCnic.isEmpty {
                                        ContactsCnic = json["ContactCNIC"].stringValue
                                    }
                                    
                                    
                                    let userModel = FriendList(name: name, number: number, userImage: userImage, ContactsCnic: ContactsCnic,userId: userId)
                                    profilesList.append(userModel)
                                    
//                                    self.removeFirend(foneId: contactCNIC, friendId: userId, url: removeMyFriend) { (model, boolVal) in   }
                                }
                                completion(profilesList,true)
                            }else{
                                completion(nil,false)
                            }
                        }
                        else{
                            completion(nil,false)
                            if let topVc = topViewController() {
                                topVc.showAlert(response?.error?.localizedDescription ?? "JSON Error")
                            }
                        }
                    }else{
                        completion(nil,false)
                        if let topVc = topViewController() {
                            topVc.showAlert(response?.error?.localizedDescription ?? "Request Error")
                        }
                    }
                }
            }
        }
    }
}
