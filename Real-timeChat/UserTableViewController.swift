//
//  NewMessageTableViewController.swift
//  Real-timeChat
//
//  Created by Jay on 12/12/2016.
//  Copyright © 2016 Jay. All rights reserved.
//

import UIKit
import Firebase

class UserTableViewController: UITableViewController {
    
    let cellId = "userCellId"
    
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancelButton))
        
        tableView.register(UserCell.self , forCellReuseIdentifier: cellId)
        
        fetchUser()
        
        
    }
    
    func fetchUser() {
        FIRDatabase.database().reference().child("users").observe(.childAdded, with:
            { (snapshot) in
                
                if let dic = snapshot.value as? [String: AnyObject]{
                    let user = User()
                    user.id = snapshot.key
                    //                    user.name = dic["name"] as! String?
                    //                    user.email = dic["email"] as! String?
                    user.setValuesForKeys(dic)
                    self.users.append(user)
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    
                }
                
                
        }, withCancel: nil)
    }
    
    func handleCancelButton() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell
        let user = users[indexPath.row]
        cell?.textLabel?.text = user.name
        cell?.detailTextLabel?.text = user.email
        
        if let profileImageURL = user.profileImageURL {
            cell?.profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
        }
        
        return cell!
    }
    
    var messageController: MessageController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: {
            let user = self.users[indexPath.row]
            self.messageController?.showChatController(user: user)
        })
    }
    
    
}

