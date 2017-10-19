//
//  Transaction.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 05/04/2017.
//
// Generic Model Class to describe a transaction between to users

import UIKit

class Transaction: NSObject {
    var uid: String
    var fromUser: String
    var toUser: String
    var service: String
    var seeds: Int
    var message : String
    var accepted : String
    var date : String
    
    
    init(uid: String, fromUser: String, toUser: String, service : String, seeds: Int, message :  String, accepted : String, date : String) {
        self.uid = uid
        self.fromUser = fromUser
        self.toUser = toUser
        self.service = service
        self.seeds = seeds
        self.message = message
        self.accepted = accepted
        self.date = date
    }
    
    convenience override init() {
        self.init(uid: "", fromUser: "", toUser: "", service : "", seeds: 0, message : "", accepted : "", date : "")
    }
    
}
