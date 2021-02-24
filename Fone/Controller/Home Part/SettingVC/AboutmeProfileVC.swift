//
//  AboutmeProfileVC.swift
//  Fone
//
//  Created by Manish Chaudhary on 10/02/21.
//  Copyright © 2021 Optechno. All rights reserved.
//

import UIKit
import CoreLocation
import NVActivityIndicatorView
class AboutmeProfileVC: UIViewController,UITextViewDelegate {
    @IBOutlet weak var lblcount: UILabel!
    @IBOutlet weak var txtaboutme: UITextView!
    @IBOutlet weak var imgvvv: UIImageView!
    @IBOutlet weak var imgyconst: NSLayoutConstraint!
    var Userid = ""
    var locationtext = ""
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()

        
        if let aboutme =  UserDefaults.standard.value(forKey: "about") as? String
        {
            self.txtaboutme.text = aboutme
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
//        self.navigationController?.setNavigationBarHidden(true, animated: false)
       
        if appDelegateShareInst.isLocationPermissionGranted{
        appDelegateShareInst.getLocationAccess()
            
            let location = CLLocation(latitude: GLBLatitude, longitude: GLBLongitude)
            location.placemark { [self] placemark, error in
                guard let placemark = placemark else {
                    print("Error:", error ?? "nil")
                    return
                }
                
                debugPrint("Location",placemark.areasOfInterest,placemark.city,placemark.name,placemark.postalAddress,placemark.postalAddressFormatted)
    //            location = placemark
                self.locationtext = placemark.postalAddressFormatted ?? (placemark.name ?? "Unknwon")
                print(placemark.postalAddressFormatted ?? "")
            }
            
        }
        else{
            locationstatus()
        }
        
      
          // here you can call the start location function

        lblcount.text =  "37/180"
        // Do any additional setup after loading the view.
    }
    
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                imgyconst.constant -=  140
                self.view.layoutIfNeeded()

            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if imgyconst.constant != 0 {
            imgyconst.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func locationstatus()
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
                
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            appDelegateShareInst.getLocationAccess()
        }
    }
   
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Hey there! I am using Fone Messenger."
        {
            textView.text = ""
        }
        
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if textView.text == ""
        {
            textView.text = "Hey there! I am using Fone Messenger."
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        lblcount.text = String(numberOfChars) + "/180"
        return numberOfChars < 180    // 10 Limit Value
    }
    
    //MARK:- API CALL FOR ABOUT US
    
    func callAPIAbout()
    {
        let current = UIDevice.modelName
        activityIndicator.startAnimating()
        let param : [String: Any] = ["UserID":Userid,"Location":locationtext,"PhoneModel":current,"PhoneBrand":"iPhone","AboutMe":txtaboutme.text ?? "Hey there! I am using Fone Messenger."]
        
        var headers = [String:String]()
        headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(updateAboutme, params: param, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true

                let statusCode = json["StatusCode"].string ?? ""
                
                if statusCode == "200" || statusCode == "201"
                {
                    UserDefaults.standard.setValue(self.txtaboutme.text, forKey: "about")
                    UserDefaults.standard.synchronize()
//                    self.callTABBAR()
                    self.navigationController?.popViewController(animated: true)
                }
                else
                {
                    if let message = json["Message"].string
                    {
                        print(message)
                        self.errorAlert("\(message)")
//                        self.callTABBAR()
                    }
                    
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
        }
        
    }
    
    func callTABBAR()
    {
//        self.navigationController?.setNavigationBarHidden(false, animated: false)

        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func Done(_ sender: Any) {
        
        callAPIAbout()
        
    }
    @IBAction func btnback(_ sender: Any) {
        callTABBAR()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

