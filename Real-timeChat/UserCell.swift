//
//  UserCell.swift
//  Real-timeChat
//
//  Created by Jay on 12/12/2016.
//  Copyright © 2016 Jay. All rights reserved.
//

import UIKit
import Firebase

class UserCell: UITableViewCell {
    
    var message:Message? {
        didSet{
            setupNameAndProfileImage()
            if self.message?.text != nil {
                self.detailTextLabel?.text = self.message?.text
            }else if self.message?.videoURL != nil{
                self.detailTextLabel?.text = "[Video]"
            }else {
                self.detailTextLabel?.text = "[Image]"
            }
            
            if let seconds = message?.timestamp?.doubleValue {
                let timestamp = NSDate(timeIntervalSince1970: seconds)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm:ss a"
                timeLabel.text = dateFormatter.string(from: timestamp as Date)                }
        }
    }
    
    private func setupNameAndProfileImage() {
        if let id = self.message?.chatmateId() {
            let ref = FIRDatabase.database().reference().child("users").child(id)
            ref.observeSingleEvent(of: .value, with: {
                (snapshot) in
                if let dic = snapshot.value as? [String: AnyObject]{
                    self.textLabel?.text = dic["name"] as? String
                    
                    if let profileImageURL = dic["profileImageURL"] as? String{
                        self.profileImageView.loadImageUsingCacheWithURLString(profileImageURL)
                    }
                }
            }, withCancel: nil)
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.frame = CGRect(x: 64, y: (textLabel?.frame.origin.y)! - 3, width: (textLabel?.frame.width)!, height: (textLabel?.frame.height)!)
        detailTextLabel?.frame = CGRect(x: 64, y: (detailTextLabel?.frame.origin.y)! + 3, width: (detailTextLabel?.frame.width)!, height: (detailTextLabel?.frame.height)!)
    }
    
    
    let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(named: "blank")
        iv.layer.cornerRadius = 24
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        //        label.text = "HH:MM:SS"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?){
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        addSubview(timeLabel)
        
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 16).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: (textLabel?.heightAnchor)!).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
