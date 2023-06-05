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
class AboutMeVC: UIViewController,UITextViewDelegate,UITextFieldDelegate {

    @IBOutlet weak var lblcount: UILabel!
    @IBOutlet weak var txtaboutme: UITextView!
    var Userid = ""
    var locationtext = ""
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
    @IBOutlet weak var imgyconst: NSLayoutConstraint!
    @IBOutlet weak var txtProfession: UITextField!
    
    @IBOutlet weak var imageTake: UIImageView!
    var pickerController = UIImagePickerController()
    
    var isupdtval = true

//    let location = CLLocation()
    override func viewDidLoad() {
        super.viewDidLoad()

        txtaboutme.delegate = self
        lblcount.text =  "0/180"
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
                
                var locattext = ""
//                if let name = placemark.name
//                {
//                    locattext = name
//                }
                if let city = placemark.city
                {
                    locattext = locattext + "" + city
                }
               if let state = placemark.state{
                locattext = locattext + ", " + state
                }
                if let state = placemark.country{
                    locattext = locattext + ", " + state
                 }
                self.locationtext = locattext
                
                print(placemark.postalAddressFormatted ?? "")
            }
        }
        else{
            locationstatus()
        }
        
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
        let param : [String: Any] = ["UserID":Userid,"Address":locationtext,"PhoneModel":current,"PhoneBrand":"iPhone","AboutMe":txtaboutme.text ?? "Hey there! I am using fone messenger.", "Profession": txtProfession.text ?? ""]
        
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

extension AboutMeVC : UINavigationControllerDelegate, UIImagePickerControllerDelegate
{
//MARK: - Take image
    @IBAction func takePhoto(_ sender: UIButton)
    {
        let alertViewController = UIAlertController(title: "", message: "Choose your option", preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default, handler: { (alert) in
            self.openCamera()
        })
        let gallery = UIAlertAction(title: "Gallery", style: .default) { (alert) in
            self.openGallary()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in

        }
        alertViewController.addAction(camera)
        alertViewController.addAction(gallery)
        alertViewController.addAction(cancel)
        self.present(alertViewController, animated: true, completion: nil)
    }

    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            pickerController.delegate = self
            self.pickerController.sourceType = UIImagePickerController.SourceType.camera
            pickerController.allowsEditing = true
            self .present(self.pickerController, animated: true, completion: nil)
        }
        else {
            let alertWarning = UIAlertView(title:"Warning", message: "You don't have camera", delegate:nil, cancelButtonTitle:"OK", otherButtonTitles:"")
            alertWarning.show()
        }
    }
    
    func openGallary() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            pickerController.delegate = self
            pickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
            pickerController.allowsEditing = true
            self.present(pickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        pickerController.dismiss(animated: true, completion: nil)
        imageTake.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        imageTake.layer.cornerRadius = imageTake.frame.size.width / 2.0
        
    }
}
