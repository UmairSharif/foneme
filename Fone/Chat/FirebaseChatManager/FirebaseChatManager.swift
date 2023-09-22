//
//  FirebaseChatManager.swift
//  Fone
//
//  Created by Sujit baranwal on 11/09/23.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import Foundation
import Firebase
import FirebaseCore
import FirebaseStorage
import FirebaseDatabase
import SendBirdSDK

class Message: NSObject {
    
    var senderId: String?
    var toId: String?
    var text: String?
    var timestamp: Int64?
    
    var imageUrl: String?
    var imageHeight: Double?
    var imageWidth: Double?
    
    init(from dictionary: [String: Any]) {
        self.text = dictionary[MessageFields.text] as? String
        self.senderId = dictionary[MessageFields.senderId] as? String ?? "Sender not found"
        self.toId = dictionary[MessageFields.receiverId] as? String ?? "Reciever not found"
        self.timestamp = dictionary[MessageFields.timestamp] as? Int64
        self.imageUrl = dictionary[MessageFields.imageUrl] as? String
        self.imageWidth = dictionary[MessageFields.imageWidth] as? Double
        self.imageHeight = dictionary[MessageFields.imageHeight] as? Double
    }
    
    func chatPartnerId() -> String? {
        if senderId == Auth.auth().currentUser?.uid {
            return toId
        } else {
            return senderId
        }
    }
    
    func toDictionary() -> [String: Any] {
        var dictionary = Dictionary<String, Any>()
        dictionary[MessageFields.text] = self.text
        dictionary[MessageFields.senderId] = self.senderId
        dictionary[MessageFields.receiverId] = self.toId
        dictionary[MessageFields.timestamp] = self.timestamp
        dictionary[MessageFields.imageUrl] = self.imageUrl
        dictionary[MessageFields.imageWidth] = self.imageWidth
        dictionary[MessageFields.imageHeight] = self.imageHeight
        return dictionary
    }
    
    func getSBDUserMessageObject() {
        var sbMessageObject = SBDBaseMessage(dictionary: self.toDictionary())
    }
}

class FirebaseChatManager {
    
    static let shared: FirebaseChatManager = FirebaseChatManager()
    private let ref = Database.database().reference()
    private var storageRef: StorageReference!
    private var messages: [DataSnapshot] = []
    
    private init() {
        configureStorage()
        receiveMessageObserver()
    }
    
    deinit {
            
//        self.ref.child("messages").removeObserver(withHandle: _refHandle)
    }
    
    func setUserInFirebase(from loggedInUserId: String? = userProfile.userId) {
        guard let uid = Auth.auth().currentUser?.uid,
        let userId = loggedInUserId else {
            return
        }
        self.ref.child("users").child(userId).setValue(uid, andPriority: .none) { error, reference in
            if error != nil {
                debugPrint("error ==> ", error?.localizedDescription)
            }
        }
    }
    
    func loggedInUserFirebaseId() -> String? {
        guard let uid = Auth.auth().currentUser?.uid else {
            return nil
        }
        return uid
    }
    
    func configureStorage() {
        storageRef = Storage.storage().reference()
    }
    
    func frameMessage(from text: String, receiverId: String) -> Message? {
        guard let currentFirebaseUser = Auth.auth().currentUser else {
            return nil
        }
        
        var mdata = Dictionary<String, Any>()
        mdata[MessageFields.text] = text
        mdata[MessageFields.name] = Auth.auth().currentUser?.displayName
        mdata[MessageFields.senderId] = currentFirebaseUser.uid
        mdata[MessageFields.receiverId] = receiverId
        mdata[MessageFields.timestamp] = Date.currentTimeStamp
        let messageObject = Message(from: mdata)
        return messageObject
    }
    
    func sendMessage(withData data: [String: Any]) {
        //setting the message in sender id list
        if let senderId = data[MessageFields.senderId] as? String,
            let timeStamp = data[MessageFields.timestamp] as? Int64,
            let receiverId = data[MessageFields.receiverId] as? String {
            let stringTimeStamp = String(timeStamp)
            self.ref.child("messages").child(senderId).child(receiverId).child(stringTimeStamp).setValue(data)
        }
        
        //setting the message in receiver id list
        if let receiverId = data[MessageFields.receiverId] as? String,
           let senderId = data[MessageFields.senderId] as? String,
            let timeStamp = data[MessageFields.timestamp] as? Int64 {
            let stringTimeStamp = String(timeStamp)
            self.ref.child("messages").child(receiverId).child(senderId).child(stringTimeStamp).setValue(data)
        }
    }
    
    func getUserMessages(receiverId: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        ref.child("messages").child(uid).child(receiverId).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                let message = Message(from: dictionary)
            }
        }, withCancel: { (nil) in

        })
    }
        
    func receiveMessageObserver() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
//        ref.child("messages").child(uid).queryOrdered(byChild: "timestamp").queryStarting(atValue: Date.currentTimeStamp + 1)
        ref.child("messages").child(uid).observe(.value) { (snapshot: DataSnapshot) in
            if let arrayOfMessageDictionary = snapshot.value as? [String: Any] {
                for (_, value) in arrayOfMessageDictionary {
                    if let messageDictionary = value as? [String: Any] {
                        let timeStampIds = messageDictionary.keys.sorted()
                        if timeStampIds.isEmpty == false,
                            let recentTimestampId = timeStampIds.last,
                            let recentMessageDictionary = messageDictionary[recentTimestampId] as? [String: Any] {
                            let messageObject = Message(from: recentMessageDictionary)
                            debugPrint("firebase message received ===>> ", messageObject.text)
                            NotificationCenter.default.post(name: NSNotification.Name("recentmessage"), object: messageObject)
                        }
                    }
                }
            }
        }
    }
    
    func getUser(from userId: String?, completionHandler: @escaping (String?) -> Void ) {
                
        guard let userIdValue = userId else {
            return
        }
        
        let ref = ref.child("users").child(userIdValue)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let firebaseId = snapshot.value as? String {
                completionHandler(firebaseId)
            }
            
        }, withCancel: { (nil) in
            completionHandler(.none)
        })

            
    }
    
    func downloadImage(from messageSnapshot: DataSnapshot, completionHandler: @escaping(UIImage?) -> Void) {
        guard let message = messageSnapshot.value as? [String:String] else {
            completionHandler(nil)
            return
        }
//        let name = message[MessageFields.name] ?? ""
        if let imageURL = message[MessageFields.imageURL] {
            if imageURL.hasPrefix("gs://") {
                Storage.storage().reference(forURL: imageURL).getData(maxSize: INT64_MAX) {(data, error) in
                    if let error = error {
                        debugPrint("Error downloading: \(error)")
                        completionHandler(nil)
                        return
                    } else if let dataObject = data,
                              let imageObject = UIImage(data: dataObject) {
                        completionHandler(imageObject)
                        return
                    }
                }
            } else if let URL = URL(string: imageURL), let data = try? Data(contentsOf: URL),
                      let imageObject = UIImage(data: data) {
                completionHandler(imageObject)
            }
        } else {
//            if let photoURL = message[MessageFields.photoURL],
//               let URL = URL(string: photoURL),
//               let data = try? Data(contentsOf: URL),
//               let imageObject = UIImage(data: data) {
//                completionHandler(imageObject)
//            }
        }
    }
    
    func sendImageMessage(from referenceURL: String?, fullSizeImageURL: String?) {
        
        guard let uid = Auth.auth().currentUser?.uid,
              let fileSizeURL = fullSizeImageURL else { return }
        
        // if it's a photo from the library, not an image from the camera
        //        if #available(iOS 8.0, *), let referenceURL = info[UIImagePickerControllerReferenceURL] as? URL {
        //          let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceURL], options: nil)
        //          let asset = assets.firstObject
        //          asset?.requestContentEditingInput(with: nil, completionHandler: { [weak self] (contentEditingInput, info) in
        //            let imageFile = contentEditingInput?.fullSizeImageURL
        //            let imageFile = fullSizeImageURL
        let imageFile = URL(fileURLWithPath: fileSizeURL)
        let filePath = "\(uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\((referenceURL as AnyObject).lastPathComponent!)"
        //            guard let strongSelf = self else { return }
        self.storageRef.child(filePath).putFile(from: imageFile, metadata: nil) { (metadata, error) in
            if let error = error {
                let nsError = error as NSError
                print("Error uploading: \(nsError.localizedDescription)")
                return
            }
            self.sendMessage(withData: [MessageFields.imageURL: self.storageRef.child((metadata?.path)!).description])
        }
        //          })
        //        }
        //        else {
        //          guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        //          let imageData = UIImageJPEGRepresentation(image, 0.8)
        //          let imagePath = "\(uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        //          let metadata = StorageMetadata()
        //          metadata.contentType = "image/jpeg"
        //          self.storageRef.child(imagePath)
        //            .putData(imageData!, metadata: metadata) { [weak self] (metadata, error) in
        //              if let error = error {
        //                print("Error uploading: \(error)")
        //                return
        //              }
        //              guard let strongSelf = self else { return }
        //              strongSelf.sendMessage(withData: [MessageFields.imageURL: strongSelf.storageRef.child((metadata?.path)!).description])
        //          }
        //        }
    }
}
