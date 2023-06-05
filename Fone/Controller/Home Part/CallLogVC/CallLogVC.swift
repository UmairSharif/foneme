//
//  CallLogVC.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import SwiftyJSON
import SVProgressHUD

struct MissCallData {

    var number: String?
    var userImage: String?
    var status: String?
    var dateTime: String?
    var name: String?

    var callerId: String?
    var receiverId: String?
    var callerFoneId: String?
    var receiverFoneId: String?
}


class CallLogVC: UIViewController {

    //IBOutet and Variables
    @IBOutlet weak var callLogTVC: UITableView!
    @IBOutlet weak var emptyLbl: UILabel!
    @IBOutlet weak var callBtn: UIButton!
    @IBOutlet weak var Segment: UISegmentedControl!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchField: UITextField!

    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!
    var logArray = [CallLog]()
    var missCallArray = [MissCallData]()
    var userNumber: String?
    var status: String = "All"
    var refreshControl = UIRefreshControl()
    let network = NetworkManager.sharedInstance
    var netStatus: Bool?
    /// Filter call logs
    private var filterCallLogs: [CallLog] = []
    private var isFilterMode = false

    override func viewDidLoad() {
        super.viewDidLoad()

        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        self.callLogTVC.keyboardDismissMode = .interactive
        self.emptyLbl.isHidden = true
        self.callBtn.isHidden = true
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        callLogTVC.addSubview(refreshControl)
        callLogTVC.tableFooterView = UIView.init()

        let fullString = NSMutableAttributedString(string: "To start calling contacts who have the Fone app, tap  ")
        // create our NSTextAttachment
        let image1Attachment = NSTextAttachment()
        if #available(iOS 13.0, *) {
            image1Attachment.image = UIImage(named: "ic_call_top")?.withTintColor(#colorLiteral(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))
        } else {
            // Fallback on earlier versions
            image1Attachment.image = UIImage(named: "ic_call_top")
        }
        image1Attachment.bounds = CGRect(x: 0, y: -5, width: 20, height: 20)

        // wrap the attachment in its own attributed string so we can append it
        let image1String = NSAttributedString(attachment: image1Attachment)

        // add the NSTextAttachment wrapper to our full string, then add some more text.

        fullString.append(image1String)
        fullString.append(NSAttributedString(string: "  at the bottom of your screen."))

        // draw the result in a label
        self.emptyLbl.attributedText = fullString
        var showLoader = true
        if let logData = UserDefaults.standard.object(forKey: "Contacts") as? Data {
            if let logs = try? PropertyListDecoder().decode([JSON].self, from: logData) {
                if logs.count > 0 {
                    showLoader = false
                }
            }
        }


        self.getCallLogAPI(showLoader: showLoader)

        network.reachability.whenReachable = { reachability in

            self.netStatus = true
            UserDefaults.standard.set("Yes", forKey: "netStatus")
            UserDefaults.standard.synchronize()

            //Get Call Logs API
            self.getCallLogAPI(showLoader: showLoader)
        }

        network.reachability.whenUnreachable = { reachability in

            self.netStatus = false
            UserDefaults.standard.set("No", forKey: "netStatus")
            UserDefaults.standard.synchronize()

            let alertController = UIAlertController(title: "No Internet!", message: "Please connect your device to the internet.", preferredStyle: .alert)

            let action1 = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in

            }

            alertController.addAction(action1)
            self.present(alertController, animated: true, completion: nil)

        }
        
        self.searchView.layer.cornerRadius = 16.0
        searchField.delegate = self
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        isFilterMode = false
        loadCallLogsFromCache()
        self.getCallLogAPI(showLoader: true)

    }
    @IBAction func segmentSelected(sender: UISegmentedControl)
    {
        if sender.selectedSegmentIndex == 0
        {
            self.status = "All"
            self.callLogTVC.reloadData()
        }
        else {
            self.status = "Missed"
            self.callLogTVC.reloadData()
        }
    }
    func loadCallLogsFromCache() {


        guard let logData = UserDefaults.standard.object(forKey: "CallLogArray") as? Data else {
            return
        }
        guard let logs = try? PropertyListDecoder().decode([JSON].self, from: logData) else {
            return
        }

        self.logArray.removeAll()
        self.missCallArray.removeAll()

        for log in logs
        {
            let dict = log.dictionary

            debugPrint(dict ?? "")

            let dateTime = dict?["CallStartTime"]?.string ?? ""
            let userImage = dict?["CallLogImage"]?.string ?? ""
            let status = dict?["CallLogStatus"]?.string ?? ""
            let number = dict?["CallLogNumber"]?.string ?? ""
            let name = dict?["CallLogName"]?.string ?? ""
            let callerFoneId = dict?["CallerFoneId"]?.string ?? ""
            let callingFoneId = dict?["CallingFoneId"]?.string ?? ""
            let callerUserId = dict?["CallerUserId"]?.string ?? ""
            let callingUserId = dict?["CallingUserId"]?.string ?? ""

            /*if status == "Missed"
            {
                let getData = MissCallData(number: number, userImage: userImage, status: status, dateTime: dateTime, name: name, callerId: callerUserId, receiverId: callingUserId, callerFoneId: callerFoneId, receiverFoneId: callingFoneId)
                self.missCallArray.append(getData)
            }*/

            ///if status != ""
            //{
                let getData = CallLog(number: number, userImage: userImage, status: status, dateTime: dateTime, name: name, callerId: callerUserId, receiverId: callingUserId, callerFoneId: callerFoneId, receiverFoneId: callingFoneId)
                self.logArray.append(getData)
            //}
        }

        self.logArray.reverse()
        self.missCallArray.reverse()
        self.callLogTVC.reloadData()

    }


    @objc func refresh() {

        //Get Call Logs API
        getCallLogAPI(showLoader: true)

        refreshControl.endRefreshing()
    }

    @IBAction func allBtnTapped(_ sender: UIButton)
    {
        self.status = "All"
        self.callLogTVC.reloadData()
    }

    @IBAction func missBtnTapped(_ sender: UIButton)
    {
        self.status = "Missed"
        if missCallArray.count == 0 {
            getCallLogAPI(showLoader: true)
        }
        self.callLogTVC.reloadData()
    }

    @IBAction func editBtnTapped(_ sender: UIButton)
    {

    }

    @IBAction func callBtnTapped(_ sender: UIButton)
    {
        let vc = UIStoryboard().loadCallVC()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func friendBtnTapped(_ sender: UIButton)
    {
        let vc = UIStoryboard().loadLocalContactVC()
        vc.hidesBottomBarWhenPushed = true
        vc.logStatus = true
        self.navigationController?.pushViewController(vc, animated: true)
    }

    private func showIndicatorView() {
        SVProgressHUD.show()
    }

    private func hideIndicatorView() {
        SVProgressHUD.dismiss()
        self.activityIndicator.isHidden = true
    }

    func getCallLogAPI(showLoader: Bool)
    {
        if showLoader {
            self.showIndicatorView()
        } else {
            self.hideIndicatorView()
        }

        var userId: String?

        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId
                userNumber = user.mobile
            }
        }
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        let params = ["UserId": userId ?? ""
        ] as [String: Any]

        print("params: \(params)")
        var headers = [String: String]()
        headers = ["Content-Type": "application/json",
            "Authorization": "bearer " + loginToken!]
        print("headers: \(headers)")

        ServerCall.makeCallWitoutFile(getCallLogsUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in

            self.hideIndicatorView()

            if let json = response {

                self.logArray.removeAll()
                self.missCallArray.removeAll()

                let callLogs = json["CallLogs"].array

                if let callLogsArray = callLogs, callLogsArray.count > 0 {
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(callLogsArray), forKey: "CallLogArray")
                    UserDefaults.standard.synchronize()
                }

                if callLogs?.count == 0 {
                    self.emptyLbl.isHidden = false
                    self.callBtn.isHidden = false
                } else {
                    self.emptyLbl.isHidden = true

                    for log in callLogs ?? []
                    {
                        let dict = log.dictionary

                        let dateTime = dict?["CallStartTime"]?.string ?? ""
                        let userImage = dict?["CallLogImage"]?.string ?? ""
                        let status = dict?["CallLogStatus"]?.string ?? ""
                        let number = dict?["CallLogNumber"]?.string ?? ""
                        let name = dict?["CallLogName"]?.string ?? ""
                        let callerFoneId = dict?["CallerFoneId"]?.string ?? ""
                        let callingFoneId = dict?["CallingFoneId"]?.string ?? ""
                        let callerUserId = dict?["CallerUserId"]?.string ?? ""
                        let callingUserId = dict?["CallingUserId"]?.string ?? ""

                        /* if status == "Missed"
                        {
                            let getData = MissCallData(number: number, userImage: userImage, status: status, dateTime: dateTime, name: name, callerId: callerUserId, receiverId: callingUserId, callerFoneId: callerFoneId, receiverFoneId: callingFoneId)
                            self.missCallArray.append(getData)
                        }*/

                        //if status != ""
                        //{
                            let getData = CallLog(number: number, userImage: userImage, status: status, dateTime: dateTime, name: name, callerId: callerUserId, receiverId: callingUserId, callerFoneId: callerFoneId, receiverFoneId: callingFoneId)
                            self.logArray.append(getData)
                        /*} else {
                            let getData = MissCallData(number: number, userImage: userImage, status: "Missed", dateTime: dateTime, name: name, callerId: callerUserId, receiverId: callingUserId, callerFoneId: callerFoneId, receiverFoneId: callingFoneId)
                            self.missCallArray.append(getData)
                        }*/
                    }

                    self.logArray.reverse()
                    self.missCallArray.reverse()
                    print(self.logArray.count, self.missCallArray.count)
                    //Reload Table View
                    self.callLogTVC.reloadData()
                }
            }
        }
    }

    private func searchByKeyword(_ keyword: String) {
        isFilterMode = !keyword.isEmpty
        filterCallLogs = logArray.filter({$0.name != nil && $0.name!.uppercased().contains(keyword.uppercased())})
        self.callLogTVC.reloadData()
    }
}
extension CallLogVC: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if status == "All" {
            return  isFilterMode ? filterCallLogs.count : logArray.count
        }
        return missCallArray.count

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath) as! CallLogTVC
        cell.callLog =  isFilterMode ? filterCallLogs[indexPath.row] : logArray[indexPath.row]

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.showIndicatorView()
        self.view.isUserInteractionEnabled = false

        if status == "All" {
            let log =  isFilterMode ? filterCallLogs[indexPath.row] : logArray[indexPath.row]

            let vc = UIStoryboard().loadVideoCallVC()
            vc.recieverNumber = log.number
            vc.name = log.name ?? ""
            vc.userImage = log.userImage
            vc.DialerFoneID = log.receiverFoneId ?? ""
            self.getUserDetail(cnic: log.receiverFoneId!, friend: "") { (user, success) in
                if success {
                    self.hideIndicatorView()
                    self.view.isUserInteractionEnabled = true
                    vc.userDetails = user!
                    vc.modalPresentationStyle = .fullScreen
                    NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.hideIndicatorView()
                    self.view.isUserInteractionEnabled = true
                    self.showAlert("Error"," Can't get user information. Please try again.")
                }
            }
        }
        else
        {
            let log = missCallArray[indexPath.row]
            let vc = UIStoryboard().loadVideoCallVC()
            vc.recieverNumber = log.number
            vc.name = log.name ?? ""
            vc.userImage = log.userImage
            vc.DialerFoneID = log.receiverFoneId ?? ""
            self.getUserDetail(cnic: log.receiverFoneId!, friend: "") { (user, success) in
                if success {
                    self.hideIndicatorView()
                    self.view.isUserInteractionEnabled = true
                    vc.userDetails = user!
                    vc.modalPresentationStyle = .fullScreen
                    NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.hideIndicatorView()
                    self.view.isUserInteractionEnabled = true
                    self.showAlert("Error"," Can't get user information. Please try again.")
                }
            }
        }

    }
}

extension CallLogVC: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        isFilterMode = true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        isFilterMode = !textField.text!.isEmpty
        self.callLogTVC.reloadData()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            let txtAfterUpdate = text.replacingCharacters(in: range, with: string)
            /// Search by keyword
            self.searchByKeyword(txtAfterUpdate)
        }
        return true
    }
}
