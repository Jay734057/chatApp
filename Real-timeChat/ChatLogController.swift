//
//  ChatLogController.swift
//  Real-timeChat
//
//  Created by Jay on 12/12/2016.
//  Copyright © 2016 Jay. All rights reserved.
//


import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController,UITextFieldDelegate,UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    let cellId = "cellId"
    
    var user:User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessage()
        }
    }
    
    var messages = [Message]()
    
    func observeMessage() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid, let chatmateId = user?.id else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid).child(chatmateId)
        ref.observe(.childAdded, with: {
            (snapshot) in
            let messageId = snapshot.key
            let messageRef = FIRDatabase.database().reference().child("messages").child((messageId))
            messageRef.observeSingleEvent(of: .value, with: {
                (snapshot) in
                
                guard let dic = snapshot.value as? [String:AnyObject] else{
                    return
                }
                
                //                let message = Message(dictionary: dic)
                //                message.setValuesForKeys(dic)
                
                //                if message.chatmateId() == self.user?.id{
                self.messages.append(Message(dictionary: dic))
                DispatchQueue.main.async(execute: {
                    self.collectionView?.reloadData()
//                    it will crash!!!i dont know 
                    if self.messages.count > 0 {
                        let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                        self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                    }
                })
                //                }
                
            }, withCancel: nil)
        }, withCancel: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        navigationItem.title = "Chat log controller"
        
        //        navigationItem.leftBarButtonItem?.title = "back"
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        collectionView?.keyboardDismissMode = .interactive

        setupKeyboardObservers()
    }
    
    lazy var inputContainerView: ChatInputContainerView = {
        
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
        
    }()
    
    func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let videoURL = info[UIImagePickerControllerMediaURL] as? URL {
            //upload video
            uploadForURL(url: videoURL)
        }else {
            uploadForInfo(info: info)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadForURL(url: URL) {
        let filename = NSUUID().uuidString +  ".mov"
        let uploadTask = FIRStorage.storage().reference().child("message_video").child(filename).putFile(url, metadata: nil, completion: { (metadata, error) in
            if error != nil{
                print(error!)
                return
            }
            
            if let videoURL = metadata?.downloadURL()?.absoluteString {
                
                if let thumbnailImage = self.thumbnailImageForVideoURL(fileURL: url){
                    
                    self.uploadImage(image: thumbnailImage, completion: { (imageURL) in
                        //image url???
                        let properties = ["imageURL": imageURL, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height, "videoURL": videoURL] as [String : Any]
                        self.sendMessageWithProperties(properties: properties as [String : AnyObject])
                        
                    })

                }

            }
        })
        uploadTask.observe(.progress, handler:{
            (snapshot) in
            if let completeUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completeUnitCount)
            }
        })
        
        uploadTask.observe(.success, handler: {
            (snapshot) in
            self.navigationItem.title = self.user?.name
        })
    }
    
    private func thumbnailImageForVideoURL(fileURL: URL) -> UIImage? {
        let asset = AVAsset(url: fileURL)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let image = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: image)
        }catch let error {
            print(error)
        }
        
        return nil
    }
    
    private func uploadForInfo(info: [String: Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selected = selectedImageFromPicker {
            //upload selected image
            uploadImage(image: selected, completion: { (imageURL) in
                self.uploadImageURL(url: imageURL, image: selected)

            })
//            uploadImage(image: selected)
        }

    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        //        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        //
        //        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = NSIndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath as IndexPath, at: .top, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleKeyboardWillShow(notification: Notification) {
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        
        containerBottomAnchor?.constant = -keyboardFrame!.height
        
        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func handleKeyboardWillHide(notfication: Notification) {
        let keyboardDuration = (notfication.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        
        containerBottomAnchor?.constant = 0
        
        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        //        cell.backgroundColor = UIColor.blue
        
        cell.chatLogController = self
        
        
        let message = messages[indexPath.item]
        
        cell.message = message
       
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        
        //modify the width of bubbleView
        if let text = message.text {
            cell.bubbleWidthAnchor?.constant = estimatedFrameForText(text: text).width + 32
            cell.textView.isHidden = false
        }else if message.imageURL != nil {
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        
        if message.videoURL != nil {
            cell.playButton.isHidden = false
        }else {
            cell.playButton.isHidden = true
        }
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        if let url = self.user?.profileImageURL {
            cell.profileImageView.loadImageUsingCacheWithURLString(urlString: url)
        }
        
        if message.fromId == FIRAuth.auth()?.currentUser?.uid {
            //outgoing
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            cell.bubbleLeftAnchor?.isActive = false
            cell.bubbleRightAnchor?.isActive = true
        }else {
            cell.bubbleView.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            
            cell.bubbleRightAnchor?.isActive = false
            cell.bubbleLeftAnchor?.isActive = true
        }
        
        if let url = message.imageURL {
            cell.messageImageView.loadImageUsingCacheWithURLString(urlString: url)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        } else {
            cell.messageImageView.isHidden = true
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 64
        
        let message = messages[indexPath.item]
        if let text = message.text {
            height = estimatedFrameForText(text: text).height + 20
        }else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue{
            //h1/w1 = h2/w2, h1 = h2 / w2 * w1
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    private func estimatedFrameForText(text: String) -> CGRect{
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    
    var containerBottomAnchor: NSLayoutConstraint?
    
    func handleSend() {
        if let text = inputContainerView.inputTextField.text{
            let properties = ["text": text]
            sendMessageWithProperties(properties: properties as [String : AnyObject])
        }
    }
    
    private func uploadImage(image: UIImage, completion: @escaping (_ imageURL: String) -> ()) {
        let imageName = NSUUID().uuidString
        
        let ref = FIRStorage.storage().reference().child("message_image").child(imageName)
        
        if let upload = UIImageJPEGRepresentation(image, 0.5) {
            ref.put(upload, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print(error!)
                    return
                }
                
                if let url = metadata?.downloadURL()?.absoluteString {
                    completion(url)
//                    self.uploadImageURL(url: url, image: image)
                }
            })
        }
    }
    
    func uploadImageURL(url: String, image: UIImage) {
        let properties = ["imageURL": url,"imageWidth": image.size.width, "imageHeight": image.size.height] as [String : Any]
        
        sendMessageWithProperties(properties: properties as [String : AnyObject])
    }
    
    private func sendMessageWithProperties(properties: [String: AnyObject]) {
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = FIRAuth.auth()!.currentUser!.uid
        let timestamp = Int(NSDate().timeIntervalSince1970)
        
        var values = ["toId": toId, "fromId": fromId, "timestamp": timestamp] as [String : Any]
        
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            self.inputContainerView.inputTextField.text = nil
            
            let id = childRef.key
            
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId).child(toId)
            userMessagesRef.updateChildValues([id: 1])
            
            let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessagesRef.updateChildValues([id: 1])
        }
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    var startingFrame: CGRect?
    var fakeBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    func performZoomInForImageView(iv: UIImageView) {
        
        startingImageView = iv
        startingImageView?.isHidden = true
        
        startingFrame = iv.superview?.convert(iv.frame, to: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
//        zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.image = iv.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(performZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            fakeBackgroundView = UIView(frame: keyWindow.frame)
            fakeBackgroundView?.alpha = 0
            fakeBackgroundView?.backgroundColor = UIColor.black
            keyWindow.addSubview(fakeBackgroundView!)
            
            keyWindow.addSubview(zoomingImageView)
            
            let heigth = iv.frame.height / iv.frame.width * keyWindow.frame.width
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: { 
                self.fakeBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: heigth)
                
                zoomingImageView.center = keyWindow.center
            }, completion: nil)
            
        }
    }
    
    func performZoomOut(gesture: UITapGestureRecognizer) {
        if let zoomOutImageView = gesture.view {
            zoomOutImageView.clipsToBounds = true
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: { 
                zoomOutImageView.frame = self.startingFrame!
                zoomOutImageView.layer.cornerRadius = 12
                
                self.fakeBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
            }, completion: { (completed: Bool) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
            
        }
    }
    
}
