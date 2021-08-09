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
class AboutmeProfileVC: UIViewController,UITextViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var lblcount: UILabel!
    @IBOutlet weak var txtaboutme: UITextView!
    @IBOutlet weak var imgvvv: UIImageView!
    @IBOutlet weak var imgyconst: NSLayoutConstraint!
    @IBOutlet weak var txtProfession: UITextField!

    var Userid = ""
    var locationtext = ""
    var isupdtval = true
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        txtProfession.delegate = self
        
        if let aboutme =  UserDefaults.standard.value(forKey: "about") as? String
        {
            self.txtaboutme.text = aboutme
        }
        if let prof = UserDefaults.standard.value(forKey: "profession") as? String
        {
            self.txtProfession.text = prof
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
                
                var locattext = ""
//                if let name = placemark.name
//                {
//                    locattext = name
//                }
                if let city = placemark.city
                {
                    locattext = locattext + " " + city
                }
               if let state = placemark.state{
                locattext = locattext + ", " + state
                }
                if let state = placemark.country{
                    locattext = locattext + ", " + state
                 }
                 
    //            location = placemark
                self.locationtext = locattext //placemark.postalAddressFormatted ?? (placemark.name ?? "Unknwon")
//                print(placemark.postalAddressFormatted ?? "")
            }
            
        }
        else{
            locationstatus()
        }
        
        txtaboutme.placeholder = "Hey there! I am using Fone Messenger."
        txtaboutme.delegate = self
        lblcount.text =  "\(txtaboutme.text.count)/180"
        // Do any additional setup after loading the view.
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isupdtval = false
        if imgyconst.constant != 100 {
            imgyconst.constant = 100
            self.view.layoutIfNeeded()
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        isupdtval = true
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if imgyconst.constant == 100 && isupdtval == true {
                imgyconst.constant -=  140
                self.view.layoutIfNeeded()

            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if imgyconst.constant != 100 {
            imgyconst.constant = 100
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
        isupdtval = true
        if textView.text == "Hey there! I am using Fone Messenger."
        {
            lblcount.text =  "0/180"
            textView.text = ""
        }

    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == ""
        {    isupdtval = false
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
        let param : [String: Any] = ["UserID":Userid,"Address":locationtext,"PhoneModel":current,"PhoneBrand":"iPhone","AboutMe":txtaboutme.text ?? "Hey there! I am using Fone Messenger.","Profession": txtProfession.text ?? ""]
        
        
        var headers = [String:String]()
        headers = ["Content-Type": "application/json"]
        
        debugPrint("PARAM", param)
        ServerCall.makeCallWitoutFile(updateAboutme, params: param, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true

                let statusCode = json["StatusCode"].string ?? ""
                
                if statusCode == "200" || statusCode == "201"
                {
                    UserDefaults.standard.setValue(self.txtaboutme.text, forKey: "about")
                    UserDefaults.standard.setValue(self.txtProfession.text, forKey: "profession")

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

