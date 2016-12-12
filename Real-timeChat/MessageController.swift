//
//  ViewController.swift
//  Real-timeChat
//
//  Created by Jay on 03/12/2016.
//  Copyright © 2016 Jay. All rights reserved.
//

import UIKit
import Firebase

class MessageController: UITableViewController {
    
    var messages = [Message]()
    
    var messagesDic = [String: Message]()
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"new_message_icon") , style: .plain, target: self, action: #selector(handleFetchUserList))
        
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(showChatController))
        gesture.direction = .left
        
        self.view.addGestureRecognizer(gesture)
        
        checkIfLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        //        observerMessages()
        
//        observerUserMessages()??????????
        tableView.allowsMultipleSelectionDuringEditing = true
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        //delete messages
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let message = messages[indexPath.row]
        
        if let id = message.chatmateId() {
            FIRDatabase.database().reference().child("user-messages").child(uid).child(id).removeValue(completionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    return
                }
                
                self.messagesDic.removeValue(forKey: id)
                self.attemptReloadOfTable()
                
            })
        }
    }
    
    func observerUserMessages() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: {
            (snapshot) in
            //            print(snapshot)
            let userId = snapshot.key
            FIRDatabase.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                
                let messageReference = FIRDatabase.database().reference().child("messages").child(messageId)
                
                messageReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    if let dic = snapshot.value as? [String: AnyObject]{
                        let message = Message(dictionary: dic)
                        //                        message.setValuesForKeys(dic)
                        
                        //                self.messages.append(message)
                        //only one message for each id
                        if let id = message.chatmateId() {
                            self.messagesDic[id] = message
                            
                        }
                        
                        self.attemptReloadOfTable()
                        
                    }
                    print(snapshot)
                    
                }, withCancel: nil)
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
        ref.observe(.childRemoved, with: {(snapshot) in
            self.messagesDic.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
        }, withCancel: nil)
    }
    
    var timer: Timer?
    
    private func attemptReloadOfTable() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    func handleReloadTable() {
        self.messages = Array(self.messagesDic.values)
        self.messages.sort(by: { (message1, message2) -> Bool in
            return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
        })
        
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellId")
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        
        let message = messages[indexPath.row]
        
        //        if let id = message.toId{
        //            let ref = FIRDatabase.database().reference().child("users").child(id)
        //            ref.observeSingleEvent(of: .value, with: {
        //                (snapshot) in
        //                if let dic = snapshot.value as? [String: AnyObject]{
        //                    cell.textLabel?.text = dic["name"] as? String
        //                    cell.detailTextLabel?.text = message.text
        //
        //                    if let profileImageURL = dic["profileImageURL"]{
        //                        cell.profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL as! String)
        //                    }
        //                }
        //            }, withCancel: nil)
        //        }
        cell.message = message
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        guard let chatmateId = message.chatmateId() else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("users").child(chatmateId)
        ref.observeSingleEvent(of: .value, with: {
            (snapshot) in
            guard let dic = snapshot.value as? [String: AnyObject] else {
                return
            }
            
            let user = User()
            user.id = chatmateId
            user.setValuesForKeys(dic)
            self.showChatController(user: user)
        }, withCancel: nil)
        
        //        showChatController(user: <#T##User#>)
    }
    
    func handleFetchUserList() {
        let newMessageController = NewMessageTableViewController()
        newMessageController.messageController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    func checkIfLoggedIn() {
        if FIRAuth.auth()?.currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }else {
            fetchUser()
        }
    }
    
    func fetchUser() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dic = snapshot.value as? [String: AnyObject] {
                self.navigationItem.title = dic["name"] as? String
                
                self.messages.removeAll()
                self.messagesDic.removeAll()
                self.tableView.reloadData()
                
                self.observerUserMessages()
                
            }
        }, withCancel: nil)
        
        
        
    }
    
    func handleLogout(){
        
        do {
            try FIRAuth.auth()?.signOut()
        }catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        loginController.messageController = self
        present(loginController, animated: true, completion: nil)
    }
    
    func showChatController(user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
}


