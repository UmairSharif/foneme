//
//  AddPhotosViewController.swift
//  Fone
//
//  Created by My Mac on 17/04/23.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import SendBirdSDK
import SVProgressHUD
import Alamofire
import SwiftyJSON

class AddPhotosViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {


    var phoneCode : String = ""
    var phoneNumber : String = ""
    var email : String = ""
    var name : String = ""
    var lastName : String = ""
    var user: User?
    var accessToken: String = ""
    var idGender: Int = 0
    var idealMatchId: Int = 0
    var selectedDate: String?
    var user_id = ""
    var interestsIds = [Int]()
    
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var image4: UIImageView!
    
    @IBOutlet weak var btnAddPhotos1: UIButton!
    @IBOutlet weak var btnAddPhotos2: UIButton!
    @IBOutlet weak var btnAddPhotos3: UIButton!
    @IBOutlet weak var btnAddPhotos4: UIButton!
    
    var tag:Int?
    var selectedImg:[Bool] = [false,false,false,false]
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        self.setUI()
       
        // Do any additional setup after loading the view.
    }
    
    func setUI(){
        self.btnAddPhotos1.setImage(UIImage(named: "Add Icon"), for: .normal)
        self.btnAddPhotos2.setImage(UIImage(named: "Add Icon"), for: .normal)
        self.btnAddPhotos3.setImage(UIImage(named: "Add Icon"), for: .normal)
        self.btnAddPhotos4.setImage(UIImage(named: "Add Icon"), for: .normal)
    }
    
    
    
    func callTABBAR() {
        LocalContactHandler.instance.getContacts()
        let tabBarVC = UIStoryboard().loadTabBarController()
        appDeleg.window?.rootViewController = tabBarVC
        appDeleg.window?.makeKeyAndVisible()
    }
    
    
    @IBAction func addPhotosBtn1Tapped(_ sender: UIButton) {
        self.tag = sender.tag
        self.alert(sender:sender)
    }
    
    @IBAction func addPhotosBtn2Tapped(_ sender: UIButton) {
        self.tag = sender.tag
        self.alert(sender:sender)
    }
    
    @IBAction func addPhotosBtn3Tapped(_ sender: UIButton) {
        self.tag = sender.tag
        self.alert(sender:sender)
    }
    
    @IBAction func addPhotosBtn4Tapped(_ sender: UIButton) {
        self.tag = sender.tag
        self.alert(sender:sender)
    }
    
    @IBAction func backBtnTaped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
    @IBAction func nextBtnTapped(_ sender: UIButton) {
//        guard self.selectedImg[0] || self.selectedImg[1] || self.selectedImg[2] || self.selectedImg[3] else{
//        let alert = UIAlertController(title: "Alert", message: "Select atleast one best image!", preferredStyle: UIAlertController.Style.alert)
//        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
//        self.present(alert, animated: true, completion: nil)
//           return
//        }
        
        self.SignUpAddPhotosAPI()
    }
    
    
    
    
    func alert(sender:UIButton){
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallary()
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            alert.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func openCamera()
        {
            if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera))
            {
                imagePicker.sourceType = UIImagePickerController.SourceType.camera
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
            else
            {
                let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }

        func openGallary(){
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
           if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
               if  self.tag == 1{
                self.selectedImg[0] = false
                   image1.contentMode = .scaleToFill
                image1.image = pickedImage
                self.btnAddPhotos1.setImage(UIImage(named: ""), for: .normal)
                self.selectedImg[0] = true
            }else if self.tag == 2{
                self.selectedImg[1] = false
                image2.contentMode = .scaleToFill
                image2.image = pickedImage
                self.btnAddPhotos2.setImage(UIImage(named: ""), for: .normal)
                self.selectedImg[1] = true
            }else if self.tag == 3{
                self.selectedImg[2] = false
                image3.contentMode = .scaleToFill
                image3.image = pickedImage
                self.btnAddPhotos3.setImage(UIImage(named: ""), for: .normal)
                self.selectedImg[2] = true
                
            }else{
                self.selectedImg[3] = false
                image4.contentMode = .scaleToFill
                image4.image = pickedImage
                self.btnAddPhotos4.setImage(UIImage(named: ""), for: .normal)
                self.selectedImg[3] = true
            }
              print(self.selectedImg)
              
           }
           dismiss(animated: true, completion: nil)
       }
       
       func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
           dismiss(animated: true, completion: nil)
       }
    
    func SignUpAddPhotosAPI() {
        
        SVProgressHUD.show()
        
        let image1 : UIImage? = self.image1.image
        let image2 : UIImage? = self.image2.image
        let image3 : UIImage? = self.image3.image
        let image4 : UIImage? = self.image4.image
        
        //let imageData = image!.jpegData(compressionQuality: 1)
        _ = UserDefaults.standard.string(forKey: "AccessToken")
//        var imageParams : [String : [OMFile]]?
        var imageParams:[[String:OMFile]] = []
        if image1 != nil {
            let imageFile1 = OMFile(image: image1!, of: CGSize(width: 210, height: 210))
            let imageParam1 = ["Userimgs1" : imageFile1]
            imageParams.append(imageParam1)
        }
        if image2 != nil {
            let imageFile2 = OMFile(image: image2!, of: CGSize(width: 210, height: 210))
            let imageParam2 = ["Userimgs2" : imageFile2]
            imageParams.append(imageParam2)
        }
        if image3 != nil {
            let imageFile3 = OMFile(image: image3!, of: CGSize(width: 210, height: 210))
            let imageParam3 = ["Userimgs3" : imageFile3]
            imageParams.append(imageParam3)
        }
        if image4 != nil {
            let imageFile4 = OMFile(image: image4!, of: CGSize(width: 210, height: 210))
            let imageParam4 = ["Userimgs4" : imageFile4]
            imageParams.append(imageParam4)
        }
        if imageParams.count == 0 {
            imageParams = [[:]]
        }
 
        print(imageParams)
        
        let commaSeparatedString = interestsIds.map { String($0) }.joined(separator: ",")
        print(commaSeparatedString)
        let parameters = [
            "UserId" : self.user_id ,
            "Dob" : self.selectedDate ?? "",
            "GenderId" : "\(self.idGender)",
            "IdealMatchId" : "\(self.idealMatchId)",
            "IsNewImg" : "True",
            "PreviousImgUrls" : "",
            "PersonalInterestIds": commaSeparatedString
            ] as [String : Any]
        
         print(parameters)

        var headers = [String:String]()
        
        headers = ["Content-Type": "application/json"]
        
        print(headers)

        ServerCall.makeCallWithMultipleFile(UpdateSingnUpProfile, params: parameters as [String : Any], files: imageParams, type: Method.POST, currentView: self.view, header: headers) { (response) in
    
            if let json  = response {
                print(json)
                if json["StatusCode"].string == "200" {
                print("success")
                    self.callTABBAR()
                    
                }else {
                    let alertController = UIAlertController(title: "Error", message: "Please enter unique fone id", preferredStyle: .alert)
                    
                    let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                    }
                    
                    alertController.addAction(action1)
                    self.present(alertController, animated: true, completion: nil)

                }
                
            }
            SVProgressHUD.dismiss()
            
        }
    }
    
    func updatePrefrences(){
        let parameters = [
            "UserId" : self.user_id ,
            "Dob" : self.selectedDate ?? "",
            "GenderId" : self.idGender,
            "IdealMatchId" : self.idealMatchId,
            "IsNewImg" : "False",
            "PersonalInterestIds": self.interestsIds
            ] as [String : Any]
        
        Alamofire.request("https://test.zwilio.com/api/account/v1/updateProfilePreference",method: .post,parameters: parameters,encoding: JSONEncoding.default).responseJSON { response in
            if response.result.isSuccess {
                self.callTABBAR()
            }else {
                print("error in Addphotos VC")
            }
        }
    }
    
}



