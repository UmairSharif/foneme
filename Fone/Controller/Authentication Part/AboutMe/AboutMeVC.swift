//
//  AboutMeVC.swift
//  Fone
//
//  Created by Manish Chaudhary on 08/02/21.
//  Copyright © 2021 Optechno. All rights reserved.
//

import UIKit
import CoreLocation
import NVActivityIndicatorView
class AboutMeVC: UIViewController,UITextViewDelegate {

    @IBOutlet weak var lblcount: UILabel!
    @IBOutlet weak var txtaboutme: UITextView!
    var Userid = ""
    var locationtext = ""
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!

//    let location = CLLocation()
    override func viewDidLoad() {
        super.viewDidLoad()

      
        lblcount.text =  "37/180"
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
        
        // Do any additional setup after loading the view.
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
        let param : [String: Any] = ["UserID":Userid,"Location":locationtext,"PhoneModel":current,"PhoneBrand":"iPhone","AboutMe":txtaboutme.text ?? "Hey there! I am using fone messenger."]
        
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
                    self.callTABBAR()
                }
                else
                {
                    if let message = json["Message"].string
                    {
                        print(message)
                        self.errorAlert("\(message)")
                        self.callTABBAR()
                    }
                    
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
        }
        
    }
    
    func callTABBAR()
    {
        LocalContactHandler.instance.getContacts()
        let tabBarVC = UIStoryboard().loadTabBarController()
        appDeleg.window?.rootViewController = tabBarVC
        appDeleg.window?.makeKeyAndVisible()
    }
    
    @IBAction func Done(_ sender: Any) {
        
        callAPIAbout()
        
    }
    
    
    
    /*
    "UserID": "c46dfd1a-898c-4504-8t12-966e91a2790c", "Location":"",
    "PhoneModel":"Note 4",
    "PhoneBrand":"Samsung",
    "AboutMe":"Software Developer"
    */
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
