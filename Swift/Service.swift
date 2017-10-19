//
//  Service.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 05/04/2017.
//
// Generic Model Class to describe a service that can do some users


import UIKit

class Service: NSObject {
    var author: String
    var uid: String
    var name: String
    var descript: String?

    
    init(author: String, uid: String, name: String, descript: String?=nil) {
        self.author = author
        self.uid = uid
        self.name = name
        self.descript = descript
    }
    
    convenience override init() {
        self.init(author: "", uid: "", name: "", descript: "")
    }

}
