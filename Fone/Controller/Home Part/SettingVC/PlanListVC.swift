//
//  PlanListVC.swift
//  Fone
//
//  Created by Bester on 08/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import BraintreeDropIn
import Braintree

class PlanListVC: UIViewController {
    
    //IBoutlet and Variables
    @IBOutlet weak var contactTVC : UITableView!
    var planArray = [Any]()
   // var planArray = [SwiftyJSON.JSON]()

     var  subscriptionPlan = ""
    var  subscriptionStatus = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadBrainTreePlans()
        self.contactTVC.tableFooterView = UIView.init()
      
        self.contactTVC.reloadData()
        //        // Get Contacts Friend List
        //        self.sendContactAPI(contactsArray : LocalContactHandler.instance.contactArray)
        
        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        self.contactTVC.rowHeight = UITableView.automaticDimension
        self.contactTVC.estimatedRowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    subscriptionPlan  = UserDefaults.standard.object(forKey: SubscriptionPlan) as? String ?? ""
        subscriptionStatus  = UserDefaults.standard.object(forKey: SubscriptionStatus) as? String ?? ""

        

    }
    
    func loadBrainTreePlans(){
    
        let header  = ["Content-Type": "application/json"]
        // APIManager.sharedManager.request(getBrainTreePlans, method: Alamofire.HTTPMethod.post, parameters: nil, encoding:  JSONEncoding.default,
        
        
        ServerCall.makeCallWitoutFile(getBrainTreePlans, params: nil, type: Method.POST, currentView: nil, header: header) { (response) in
            
            //                                                self.refreshControl.endRefreshing()
            //                                                self.activityIndicator.stopAnimating()
            //                                                self.activityIndicator.isHidden = true
            //let contacts = json["Contacts"].array
            
            if let json = response {
                self.planArray = json.arrayObject ??  [Any]()
                
            }
            print(self.planArray)
            self.contactTVC.reloadData()
        }
        
    }
    
    @IBAction func backBtnTapped(_ sender : UIButton)
    {
        self.dismiss(animated: true, completion: nil)
        //self.navigationController?.popViewController(animated: true)
    }
//    
//    func pay(withPlanId:String) {
//        // Test Values
//        // Card Number: 4111111111111111
//        // Expiration: 08/2018
//        
//        let token = (IS_SANDBOX == 1) ? BrainTree_toKinizationKey : BrainTree_toKinizationKey_Pro
//        print("token == \(token)")
//        let request =  BTDropInRequest()
//        let dropIn = BTDropInController(authorization: token, request: request)
//        { [unowned self] (controller, result, error) in
//            
//            if let error = error {
//                self.show(message: error.localizedDescription)
//                
//            } else if (result?.isCanceled == true) {
//                self.show(message: "Transaction Cancelled")
//                
//            } else if let nonce = result?.paymentMethod?.nonce {
//                self.sendRequestPaymentToServer(nonce: nonce, withPlanId: withPlanId)
//            }
//            controller.dismiss(animated: true, completion: nil)
//        }
//        
//        self.present(dropIn!, animated: true, completion: nil)
//    }
    
    func sendRequestPaymentToServer(nonce: String, withPlanId: String) {
        print(nonce);
        
        var mobilenumber = ""
        var email = ""
        var fName = ""
        var lName = ""
               if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                   print(userProfileData)
                   if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                       mobilenumber = user.mobile ?? ""
                      email = user.email ?? ""
                       fName = user.name ?? ""
                   }
               }
                
        
        let paymentURL = URL(string: setSubscriptions_Customer)!
        var request = URLRequest(url: paymentURL)
        request.httpBody = "firstName=\(fName)&lastName=\(lName)&email=\(email)&phone=\(mobilenumber)&planId=\(withPlanId)&payment_method_nonce=\(nonce)".data(using: String.Encoding.utf8)
        
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) -> Void in
            guard let data = data else {
                self?.show(message: error!.localizedDescription)
                return
            }
            let str = String(decoding: data, as: UTF8.self)
            print("str = \(str)")
            let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            let subscriptionObj = result?["subscription"] as? [String:Any]
            let transactionId = subscriptionObj?["transactionId"] as? String ?? ""
            let subscriptionId = subscriptionObj?["subscriptionId"] as? String  ?? ""
            if transactionId.isEmpty {
                self?.show(message: "Transaction failed. Please try again.")
                return
            }
            print("result = \(String(describing: result))")
            UserDefaults.standard.set("Active", forKey: SubscriptionStatus)
            UserDefaults.standard.set(withPlanId, forKey: SubscriptionPlan)
            UserDefaults.standard.set(subscriptionId, forKey: SubscriptionId)
            self?.showSuccessMessage()
           // self?.show(message: "Successfully subscribed for app. Thanks So Much :)")
        }.resume()
    }
    
    func showSuccessMessage(){
        DispatchQueue.main.async {

        let alert = UIAlertController(title: "", message: "Successfully subscribed for app. Thanks So Much :)", preferredStyle: .alert)
               let actionCancel = UIAlertAction(title: "Ok", style: .cancel) { (action) in
                self.dismiss(animated: true, completion: nil);
               }
               alert.addAction(actionCancel)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    func show(message: String) {
        DispatchQueue.main.async {
            
            let alertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
}



extension PlanListVC :  UITableViewDelegate,UITableViewDataSource
{
    // UITableViewAutomaticDimension calculates height of label contents/text
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Swift 4.2 onwards
        return UITableView.automaticDimension

        // Swift 4.1 and below
       // return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.planArray.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UITableViewCell
         let titleLabel = cell.viewWithTag(11) as? UILabel
        let descriptionLabel = cell.viewWithTag(12)  as? UILabel

        let object = self.planArray[indexPath.row] as? [String:Any]
        let planName = object?["name"] as? String
        let planDescription = object?["description"] as? String
        let price = object?["price"] as? String
        let currencyIsoCode = object?["currencyIsoCode"] as? String
        print(object ?? "")

        titleLabel?.text = "\(planName ?? "") -- \(currencyIsoCode ?? "") \(price ?? "")"
        descriptionLabel?.text = planDescription ?? ""
        
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        

        if subscriptionStatus.lowercased() != "active" {
            let object = self.planArray[indexPath.row] as? [String:Any]

                   let alertController = UIAlertController(title: "Confirm", message: "Please confirm to subscribe?", preferredStyle: .alert)
                          
                          let action1 = UIAlertAction(title: "YES", style: .default) { (action:UIAlertAction) in
                             let planId = object?["id"] as? String ?? ""
                                   //  self.pay(withPlanId: planId);
                          }
                          let action2 = UIAlertAction(title: "NO", style: .cancel) { (action:UIAlertAction) in
                              
                          }
                          
                          alertController.addAction(action1)
                          alertController.addAction(action2)
                          self.present(alertController, animated: true, completion: nil)
                   
                  
        } else {
            self.show(message: "You already subscribed for app. you plan is \(subscriptionPlan)")
        }
        
       
        
    }
}


