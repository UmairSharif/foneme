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
import MapKit
import Contacts
import SwiftJWT
import SVProgressHUD

//import CoreLocation
protocol FullScreenAdsDelegate: class {
    func fullscreenAdLoaded()
    func fullscreenAdClosed()
}

public typealias isCompletion = (_ isCompleted: Bool?) -> Void

/// separate class for google sign-in methods
class FullScreenAdManager: NSObject {
    
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
    
    func hasDigits() -> Bool {
        let digitsRegex = ".*[0-9]+.*"
        return NSPredicate(format: "SELF MATCHES %@", digitsRegex).evaluate(with: self)
    }
    
    func isValidPasswordWithLength(length: Int) -> Bool {
        return (self.count > length) ? true : false
    }
    
    func isEmpty() -> Bool {
        return (self.count > 0) ? false : true
    }
    
    
    var trim: String
    {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    
  func getUserDetail(
    cnic foneId: String = "" ,
    friend friendId: String = "",
    _ completion: @escaping (_ model : UserDetailModel? , _ success : Bool) -> Void) {
      
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
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
                //let swiftyJsonData:JSON = JSON(response!)
                        if let json = response {
                            let statusCode = json["StatusCode"].string ?? ""
                            if statusCode == "200" {
                                let profileData = json["UserProfileData"]
                                var userModel = UserDetailModel(fromJson: profileData)
                                if foneId != "" {
                                    userModel.cnic = foneId
                                }
                                DispatchQueue.main.async {
                                    completion(userModel,true)
                                }
                            }
                            else{
                                DispatchQueue.main.async {
                                    completion(nil,false)
                                }
                            }
                        }else{
                            DispatchQueue.main.async {
                                completion(nil,false)
                            }
                        }
                    }
                }
            }
        }
          
//         let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String
//         loginToken.isEmpty == false
//
//        let params = ["Me":user.userId ?? "",
//                      "Url":"",
//                      "Cnic" : foneId,
//                      "Friend":friendId] as [String:Any]
//
//        print("params: \(params)")
//
//        var headers = [String:String]()
//
//        headers = ["Content-Type": "application/json",
//                   "Authorization" : "bearer " + loginToken]
//
//        ServerCall.makeCallWitoutFile(
//          getProfileUrl,
//          params: params,
//          type: Method.POST,
//          currentView: nil,
//          header: headers
//        ) { (response) in
//
//          if let json = response, let statusCode = json["StatusCode"].string, statusCode == "200" {
//
//            let profileData = json["UserProfileData"]
//            var userModel = UserDetailModel(fromJson: profileData)
//            if foneId != "" {
//              userModel.cnic = foneId
//            }
//
//            DispatchQueue.main.async {
//              completion(userModel, true)
//            }
//          } else {
//            DispatchQueue.main.async {
//              completion(nil, false)
//            }
//          }
//        }
//      } else {
//        completion(nil, false)
//      }
    }
    
    //MARK:- user details from number
    func getUserDetailPhone(cnic foneId: String = "" ,friend friendId : String = "" ,_ completion : @escaping (_ model : UserDetailModel? , _ success : Bool) -> Void )
    {
        if let user = CurrentSession.shared.user {
            
            if let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String, loginToken.isEmpty == false {
                
                let params = ["Me":user.userId ?? "",
                              "Url":"",
                              "Cnic" : foneId,
                              "Friend":friendId] as [String:Any]
                print("params: \(params)")
                
                var headers = [String:String]()
                headers = ["Content-Type": "application/json",
                           "Authorization" : "bearer " + loginToken]
                
                ServerCall.makeCallWitoutFile(getuserdetail, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
                    
                    if let json = response {
                        let statusCode = json["StatusCode"].string ?? ""
                        if statusCode == "200" {
                            let profileData = json["UserProfileData"]
                            let userModel = UserDetailModel(fromJson: profileData)
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
    
    
    
    
    //MARK:- GET USER PROFILE
    func getUserProfile(cnic foneId: String = "" ,friend friendId : String = "" ,_ completion : @escaping (_ model : UserDetailModel? , _ success : Bool) -> Void )
    {
        if let user = CurrentSession.shared.user {
            
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
                                    SVProgressHUD.dismiss()
                                    topVc.showAlert(response?.error?.localizedDescription ?? "JSON Error")
                                }
                            }
                        }else{
                            completion(nil,false)
                            if let topVc = topViewController() {
                                SVProgressHUD.dismiss()
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
    
    func searchProfession( byCnic: String ,_ completion : @escaping (_ model : [FriendList]? , _ success : Bool) -> Void )
    {
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
          //  print(userProfileData)
            if let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String, loginToken.isEmpty == false {
                
                let params = ["Profession":byCnic] as [String:Any]
                print("params: \(params)")
                
                var headers = [String:String]()
                headers = ["Content-Type": "application/json",
                           "Authorization" : "bearer " + loginToken]
                
                ServerCall.makeCallWitoutFile(searchByProfession, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
                    
                    if let json = response {
                     //   print(json)
                        let statusCode = json["StatusCode"].string ?? ""
                        if statusCode == "200" {
                            let profileData = json["UserAboutMeData"].array
                            var profilesList = [FriendList]()
                            if profileData != nil {
                                for json in profileData! {
                                    let number = json["PhoneNumber"].stringValue
                                    let name = json["FirstName"].stringValue
                                    let userImage = json["ImageURL"].stringValue
                                    var ContactsCnic = json["FoneMe"].stringValue
                                    let distance = json["Distance"].stringValue
                                    let userId = json["UserID"].stringValue
                                    if ContactsCnic.isEmpty {
                                        ContactsCnic = json["ContactCNIC"].stringValue
                                    }
                                    

                                    let userModel = FriendList(name: name, number: number, userImage: userImage, ContactsCnic: ContactsCnic, userId: userId, distance: distance)
                                    profilesList.append(userModel)
                                    
                                    
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
    
    func addSocialLink(links: [SocialLink], _ completion : @escaping (_ success : Bool) -> Void) {
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data,
           let user = try? PropertyListDecoder().decode(User.self, from: userProfileData),
           let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String,
           loginToken.isEmpty == false {
            var params = [[String: Any]]()
            links.forEach { link in
                params.append([
                    "UserID": user.userId!,
                    "Name": link.name,
                    "SocialLink": link.url,
                ] as [String: Any])
            }
            print("params: \(params)")
            
            var request = try! URLRequest(url: addSocialLinkUrl, method: .post)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("bearer " + loginToken, forHTTPHeaderField: "Authorization")
            request.httpBody = try! JSONSerialization.data(withJSONObject: params)
            
            APIManager.sharedManager.request(request)
                .responseJSON(completionHandler: { response in
                    switch response.result {
                    case .success:
                        if let data = response.data,
                           let json = try? JSON(data: data) {
                            print("json: \(json)")
                            let statusCode = json["StatusCode"].string ?? ""
                            if statusCode == "200" {
                                completion(true)
                            }
                            else{
                                completion(false)
                            }
                        } else {
                            completion(false)
                        }
                    case .failure(let error):
                        print("Error in API: \(error.localizedDescription)")
                        completion(false)
                    }
                })
        } else {
            completion(false)
        }
    }
    
    func deleteSocialLink(link: SocialLink, _ completion : @escaping (_ success : Bool) -> Void) {
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data,
           let user = try? PropertyListDecoder().decode(User.self, from: userProfileData),
           let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String,
           loginToken.isEmpty == false {
            var params = [String: Any]()
            params = [
                "UserID": user.userId!,
                "Id": link.id
            ]
            print("params: \(params)")
            
            var request = try! URLRequest(url: deleteSocialLinkUrl, method: .post)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("bearer " + loginToken, forHTTPHeaderField: "Authorization")
            request.httpBody = try! JSONSerialization.data(withJSONObject: params)
            APIManager.sharedManager.request(request)
                .responseJSON(completionHandler: { response in
                    switch response.result {
                    case .success:
                        if let data = response.data,
                           let json = try? JSON(data: data) {
                            print("json: \(json)")
                            let statusCode = json["StatusCode"].string ?? ""
                            if statusCode == "200" {
                                completion(true)
                            }
                            else{
                                completion(false)
                            }
                        } else {
                            completion(false)
                        }
                    case .failure(let error):
                        print("Error in API: \(error.localizedDescription)")
                        completion(false)
                    }
                })
        } else {
            completion(false)
        }
    }
    
    func updateSocialLink(link: SocialLink, _ completion : @escaping (_ success : Bool) -> Void) {
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data,
           let user = try? PropertyListDecoder().decode(User.self, from: userProfileData),
           let loginToken = UserDefaults.standard.object(forKey: "AccessToken") as? String,
           loginToken.isEmpty == false {
            var params = [String: Any]()
            params = [
                "UserID": user.userId!,
                "Id": link.id,
                "Name": link.name,
                "SocialLink": link.url
            ]
            print("params: \(params)")
            
            var request = try! URLRequest(url: updateSocialLinkUrl, method: .post)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("bearer " + loginToken, forHTTPHeaderField: "Authorization")
            request.httpBody = try! JSONSerialization.data(withJSONObject: params)
            APIManager.sharedManager.request(request)
                .responseJSON(completionHandler: { response in
                    switch response.result {
                    case .success:
                        if let data = response.data,
                           let json = try? JSON(data: data) {
                            print("json: \(json)")
                            let statusCode = json["StatusCode"].string ?? ""
                            if statusCode == "200" {
                                completion(true)
                            }
                            else{
                                completion(false)
                            }
                        } else {
                            completion(false)
                        }
                    case .failure(let error):
                        print("Error in API: \(error.localizedDescription)")
                        completion(false)
                    }
                })
        } else {
            completion(false)
        }
    }
    
    
    func decode(jwtToken jwt: String) throws -> [String: Any] {
        
        enum DecodeErrors: Error {
            case badToken
            case other
        }
        
        func base64Decode(_ base64: String) throws -> Data {
            let base64 = base64
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let padded = base64.padding(toLength: ((base64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
            guard let decoded = Data(base64Encoded: padded) else {
                throw DecodeErrors.badToken
            }
            return decoded
        }
        
        func decodeJWTPart(_ value: String) throws -> [String: Any] {
            let bodyData = try base64Decode(value)
            let json = try JSONSerialization.jsonObject(with: bodyData, options: [])
            guard let payload = json as? [String: Any] else {
                throw DecodeErrors.other
            }
            return payload
        }
        
        let segments = jwt.components(separatedBy: ".")
        return try decodeJWTPart(segments[1])
    }
    
    func setCacheData(completion: (()-> Void)? = nil) {
        var USER_ID: String?
        var USER_NAME: String?
        var mobileNumber: String = ""
        if let loginToken = UserDefaults.standard.string(forKey: "AccessToken"), !loginToken.isEmpty {
            do {
                let jwt = try decode(jwtToken: loginToken)
                print(jwt)
                USER_ID = jwt["uid"] as? String
                mobileNumber = jwt["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] as? String ?? ""
                if !(mobileNumber.isEmpty)
                {
                    mobileNumber.remove(at: mobileNumber.startIndex)
                }
            } catch {
                
            }
        }
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                USER_ID = user.uniqueContact
                USER_NAME = user.name ?? ""
                let userDefault = UserDefaults.standard
                userDefault.setValue(USER_ID, forKey: "sendbird_user_id")
                userDefault.setValue(USER_NAME, forKey: "sendbird_user_nickname")
                completion?()
                ConnectionManager.login(userId: USER_ID!, nickname: USER_NAME!) { user, error in
                    print(error ?? "not an error")
                    guard error == nil else {
                        return
                    }
                }
            }
        } else {
            var headers = [String:String]()
            headers = ["AuthKey": "#phone@me!Us+O0"]
            headers = ["Content-Type": "application/json"]
            ServerCall.makeCallWitoutFile(checkCICN  + "/\(mobileNumber)", params: [:], type: Method.GET, currentView: nil, header: headers) { (response) in
                
                if let json = response {
                    let cnic = json.rawString()
                    self.getUserProfile(cnic: cnic ?? "") { model, success in
                        let user = User()
                        user.userId = model?.userId
                        user.name = model?.name
                        user.aboutme = model?.aboutme
                        user.coutryCode = model?.countryCode
                        user.mobile = model?.phoneNumber
                        user.email = model?.email
                        user.numberWithOutCode = model?.mobileNumberWithoutCode
                        
                        if let userProfileData = try? PropertyListEncoder().encode(user) {
                            UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                            UserDefaults.standard.synchronize()
                            if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                                print(userProfileData)
                                if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                                    USER_ID = user.uniqueContact
                                    USER_NAME = user.name ?? ""
                                    let userDefault = UserDefaults.standard
                                    userDefault.setValue(USER_ID, forKey: "sendbird_user_id")
                                    userDefault.setValue(USER_NAME, forKey: "sendbird_user_nickname")
                                    
                                    ConnectionManager.login(userId: USER_ID!, nickname: USER_NAME!) { user, error in
                                        print(error ?? "not an error")
                                        guard error == nil else {
                                            return
                                        }
                                    }
                                }
                                
                                completion?()
                            }
                        }
                    }
                }
            }
        }
    }
}


extension CLPlacemark {
    /// street name, eg. Infinite Loop
    var streetName: String? { thoroughfare }
    /// // eg. 1
    var streetNumber: String? { subThoroughfare }
    /// city, eg. Cupertino
    var city: String? { locality }
    /// neighborhood, common name, eg. Mission District
    var neighborhood: String? { subLocality }
    /// state, eg. CA
    var state: String? { administrativeArea }
    /// county, eg. Santa Clara
    var county: String? { subAdministrativeArea }
    /// zip code, eg. 95014
    var zipCode: String? { postalCode }
    /// postal address formatted
    @available(iOS 11.0, *)
    var postalAddressFormatted: String? {
        guard let postalAddress = postalAddress else { return nil }
        return CNPostalAddressFormatter().string(from: postalAddress)
    }
}
extension CLLocation {
    func placemark(completion: @escaping (_ placemark: CLPlacemark?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(self) { completion($0?.first, $1) }
    }
}


public extension UIDevice {
    
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
#if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod touch (5th generation)"
            case "iPod7,1":                                 return "iPod touch (6th generation)"
            case "iPod9,1":                                 return "iPod touch (7th generation)"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPhone12,1":                              return "iPhone 11"
            case "iPhone12,3":                              return "iPhone 11 Pro"
            case "iPhone12,5":                              return "iPhone 11 Pro Max"
            case "iPhone12,8":                              return "iPhone SE (2nd generation)"
            case "iPhone13,1":                              return "iPhone 12 mini"
            case "iPhone13,2":                              return "iPhone 12"
            case "iPhone13,3":                              return "iPhone 12 Pro"
            case "iPhone13,4":                              return "iPhone 12 Pro Max"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad (4th generation)"
            case "iPad6,11", "iPad6,12":                    return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6":                      return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12":                    return "iPad (7th generation)"
            case "iPad11,6", "iPad11,7":                    return "iPad (8th generation)"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad11,3", "iPad11,4":                    return "iPad Air (3rd generation)"
            case "iPad13,1", "iPad13,2":                    return "iPad Air (4th generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad mini (5th generation)"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch) (1st generation)"
            case "iPad8,9", "iPad8,10":                     return "iPad Pro (11-inch) (2nd generation)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch) (1st generation)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,11", "iPad8,12":                    return "iPad Pro (12.9-inch) (4th generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "AudioAccessory5,1":                       return "HomePod mini"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
#elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
#endif
        }
        
        return mapToDevice(identifier: identifier)
    }()
    
}
