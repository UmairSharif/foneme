//
//  LocalContactHandler.swift
//  Fone
//
//  Created by Bester on 10/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import Foundation
import ContactsUI


struct Contacts {
    
    var name : String?
    var number : String?
}

class LocalContactHandler: NSObject {
    
    static let instance = LocalContactHandler()
    var contactArray = [Contacts]()
    var contacts = [CNContact]()
    
    
    func getContacts()
    {
        let contactStore = CNContactStore()
        let keys = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey
            ] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        do {
            try contactStore.enumerateContacts(with: request){
                (contact, stop) in
                // Array containing all unified contacts from everywhere
                self.contacts.append(contact)
                for phoneNumber in contact.phoneNumbers {
                    if let number = phoneNumber.value as? CNPhoneNumber {
//                        let localizedLabel = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: label)
                        
                        
                        let getData = Contacts(name: contact.givenName, number: number.stringValue)
                        self.contactArray.append(getData)
                    }
                }
            }
            
        } catch {
            print("unable to fetch contacts")
        }
    }
}
