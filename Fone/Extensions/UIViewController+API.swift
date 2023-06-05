import Foundation
import UIKit
import SwiftyJSON
import SVProgressHUD

extension UIViewController {
    func getContacts(completion: @escaping (Bool) -> Void) {
        guard let userId = CurrentSession.shared.user?.userId, let token = CurrentSession.shared.accessToken else {
            return
        }
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "bearer " + token
        ]
        print("parameters = \(["UserId": userId]) \n url = \(saveContactUrl)")
        ServerCall.makeCallWitoutFile(saveContactUrl,
                                      params: [
                                        "UserId": userId
                                      ],
                                      type: Method.POST,
                                      currentView: nil,
                                      header: headers) { json in
            guard let json = json else {
                SVProgressHUD.dismiss()
                return
                
            }

            let statusCode = json["StatusCode"].string ?? ""
            if statusCode == "401" {
                SVProgressHUD.dismiss()
                //TODO: logout and go to login screen
                return
            }
            if let contacts = json["Contacts"].array {
                if contacts.count > 0 {
                    var midConatct = [SwiftyJSON.JSON]()
                    for var items in contacts {
                        let dict = items.dictionary
                        var number = dict?["ContactsNumber"]?.string ?? ""
                        number = number.replacingOccurrences(of: " ", with: "")
                        let ContactsCnic = dict?["ContactsCnic"]?.string ?? ""

                        //let json = JSON(number)
                        items["ContactsNumber"] = JSON(number)
                        if !(ContactsCnic.isEmpty) {
                            midConatct.append(items)
                        }
                    }

                    CurrentSession.shared.storeFriends(friends: midConatct)
                    completion(true)
                } else {
                    SVProgressHUD.dismiss()
                    completion(false)
                }
            } else {
                SVProgressHUD.dismiss()
                completion(false)
            }
        }
    }
}
