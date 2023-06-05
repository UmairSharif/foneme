//
//  PhoneAuthManager.swift
//  TestFirebasePhoneVerfication
//
//  Created by iOSCoderAbhimanyuDaspan on 03/04/23.
//
import FirebaseAuth
import Foundation


class PhoneAuthManager {
    static let  shared:PhoneAuthManager = PhoneAuthManager()
    
    private var verificationId:String?
    
    private let auth = Auth.auth()
    
    //MARK: Enter Phone Number and wait for OTP
    public func startAuth(phoneNumber:String,completion: @escaping ((Bool,Error?) -> Void)){
        PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
                guard let verificationId  = verificationID , error == nil else {
                    completion(false,error)
                    return
                }
                if let `self` = self {
                    // Sign in using the verificationID and the code sent to the user
                    self.verificationId = verificationId
                    completion(true,nil)
                }
            }
    }
    
    //MARK: Pprepare Credentials and Try to SiGN IN
    public func verifyCode(otp:String,completion: @escaping ((Bool,Error?) -> Void)){
        guard let verificationId  = self.verificationId else {
            completion(false,ErrorType.noVerficationIdFound)
            return
        }
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationId,
            verificationCode: otp
        )
        auth.signIn(with: credential) { result , error in
            guard  result != nil , error == nil else {
                completion(false,error)
                return
            }
            completion(true,nil)
        }
    }
}

enum ErrorType:Error {
    case noVerficationIdFound
}
