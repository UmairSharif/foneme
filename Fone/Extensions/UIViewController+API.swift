import Foundation
import UIKit
import SwiftyJSON

extension UIViewController {
    func getContacts(completion: @escaping (Bool) -> Void) {
        guard let userId = CurrentSession.shared.user?.userId, let token = CurrentSession.shared.accessToken else {
            return
        }
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "bearer " + token
        ]

        ServerCall.makeCallWitoutFile(saveContactUrl,
                                      params: [
                                        "UserId": userId
                                      ],
                                      type: Method.POST,
                                      currentView: nil,
                                      header: headers) { json in
            guard let json = json else { return }

            let statusCode = json["StatusCode"].string ?? ""
            if statusCode == "401" {
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
                        if (number.count > Min_Contact_Number_Lenght) && !(ContactsCnic.isEmpty) {
                            midConatct.append(items)
                        }
                    }

                    CurrentSession.shared.storeFriends(friends: midConatct)
                    completion(true)
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
}
