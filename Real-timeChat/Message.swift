//
//  Message.swift
//  Real-timeChat
//
//  Created by Jay on 12/12/2016.
//  Copyright © 2016 Jay. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    var fromId: String?
    var text: String?
    var timestamp: NSNumber?
    var toId: String?
    
    var imageURL: String?
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    
    var videoURL: String?
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        
        fromId = dictionary["fromId"] as? String
        toId = dictionary["toId"] as? String
        text = dictionary["text"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        
        imageURL = dictionary["imageURL"] as? String
        imageWidth = dictionary["imageWidth"] as? NSNumber
        imageHeight = dictionary["imageHeight"] as? NSNumber
        
        videoURL = dictionary["videoURL"] as? String
    }
    
    func chatmateId() -> String? {
        if fromId == FIRAuth.auth()?.currentUser?.uid {
            return toId
        }else {
            return fromId
        }
    }
}
