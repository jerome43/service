//
//  User.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 05/04/2017.
//
// Generic Model Class to describe a user


import UIKit

class User: NSObject {
    var uid:String
    var userName: String?
    var lastName: String?
    var firstName: String?
    var location: String?
    var phoneNumber: String?
    var seeds : Int?
 

    init(uid: String, userName: String?="", lastName: String?="", firstName: String?="", location: String?="", phoneNumber: String?="", seeds: Int?=10) {
        
        self.uid = uid
        self.userName = userName
        self.lastName = lastName
        self.firstName = firstName
        self.location = location
        self.phoneNumber = phoneNumber
        self.seeds = seeds
  }
    
    convenience override init() {
        self.init(uid: "", userName: "", lastName: "", firstName: "", location: "", phoneNumber: "", seeds: 10)
    }
}
