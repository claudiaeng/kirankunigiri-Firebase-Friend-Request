//
//  DataController.swift
//  FirebaseFriendRequest
//
//  Created by Kiran Kunigiri on 7/10/16.
//  Copyright © 2016 Kiran. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FriendSystem {
    
    // MARK: - Firebase references
    /** The base Firebase reference */
    let BASE_REF = Firestore.firestore()
    /* The user Firebase reference */
    let USER_REF = Firestore.firestore().collection("users")
    
    static let system = FriendSystem()
    
    /** The Firebase reference to the current user tree */
    var CURRENT_USER_REF: DocumentReference {
        let id = Auth.auth().currentUser!.uid
        return USER_REF.document(id)
    }
    
    /** The Firebase reference to the current user's friend tree */
    var CURRENT_USER_FRIENDS_REF: CollectionReference {
        return CURRENT_USER_REF.collection("friends")
    }
    
    /** The Firebase reference to the current user's friend request tree */
    var CURRENT_USER_REQUESTS_REF: CollectionReference {
        return CURRENT_USER_REF.collection("requests")
    }
    
    /** The current user's id */
    var CURRENT_USER_ID: String {
        let id = Auth.auth().currentUser!.uid
        return id
    }
    
    
    /** Gets the current User object for the specified user id */
    func getCurrentUser(_ completion: @escaping (User) -> Void) {
        CURRENT_USER_REF.getDocument { (document, error) in
            if error == nil {
                let user = document.flatMap({
                    $0.data().flatMap({ (data) in
                        return User(dictionary: data as [String : AnyObject])
                    })
                })
                print(user as Any)
                //let email = snapshot.childSnapshot(forPath: "phoneNumber").value as! String
                //let id = document?.documentID
                //completion(User(dictionary: ["id": id as AnyObject, "phoneNumber": email as AnyObject]))
            }
        }
    }
    /** Gets the User object for the specified user id */
    func getUser(_ userID: String, completion: @escaping (User) -> Void) {
        USER_REF.document(userID).getDocument { (document, error) in
            if error == nil {
                let user = document.flatMap({
                    $0.data().flatMap({ (data) in
                        return User(dictionary: data as [String : AnyObject])
                    })
                })
                print(user as Any)
            }
        }
    }
    
    
    
    // MARK: - Account Related
    
    /**
     Creates a new user account with the specified email and password
     - parameter completion: What to do when the block has finished running. The success variable
     indicates whether or not the signup was a success
     */
    /*
     func createAccount(_ email: String, password: String, name: String, completion: @escaping (_ success: Bool) -> Void) {
     Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
     
     if (error == nil) {
     // Success
     var userInfo = [String: AnyObject]()
     userInfo = ["email": email as AnyObject, "name": name as AnyObject]
     self.CURRENT_USER_REF.setValue(userInfo)
     completion(true)
     } else {
     // Failure
     completion(false)
     }
     
     })
     }
     */
    
    /**
     Logs in an account with the specified email and password
     
     - parameter completion: What to do when the block has finished running. The success variable
     indicates whether or not the login was a success
     */
    /*
     func loginAccount(_ email: String, password: String, completion: @escaping (_ success: Bool) -> Void) {
     Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
     
     if (error == nil) {
     // Success
     completion(true)
     } else {
     // Failure
     completion(false)
     print(error!)
     }
     
     })
     }
     
     /** Logs out an account */
     func logoutAccount() {
     try! Auth.auth().signOut()
     }
     
     */
    
    // MARK: - Request System Functions
    
    /** Sends a friend request to the user with the specified id */
    func sendRequestToUser(_ userID: String) {
        USER_REF.document(userID).collection("requests").document(CURRENT_USER_ID).setValue(true)
    }
    
    /** Unfriends the user with the specified id */
    func removeFriend(_ userID: String) {
        CURRENT_USER_REF.collection("friends").document(userID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
        USER_REF.document(userID).collection("friends").document(CURRENT_USER_ID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    /** Accepts a friend request from the user with the specified id */
    func acceptFriendRequest(_ userID: String) {
        CURRENT_USER_REF.collection("requests").document(userID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
        CURRENT_USER_REF.collection("friends").document(userID)
        USER_REF.document(userID).collection("friends").document(CURRENT_USER_ID)
        USER_REF.document(userID).collection("requests").document(CURRENT_USER_ID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    
    
    // MARK: - All users
    /** The list of all users */
    var userList = [User]()
    /** Adds a user observer. The completion function will run every time this list changes, allowing you
     to update your UI. */
    func addUserObserver(_ update: @escaping () -> Void) {
        FriendSystem.system.USER_REF.addSnapshotListener { documentSnapshot, error in
            self.userList.removeAll()
            guard let documents = documentSnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            for document in documents {
                self.userList.append(User(dictionary: document.data() as [String : AnyObject]))
            }
            update()
        }
    }
    
    /** Removes the user observer. This should be done when leaving the view that uses the observer. */
    func removeUserObserver() {
        let listener = USER_REF.addSnapshotListener { querySnapshot, error in
            // ...
        }
        // Stop listening to changes
        listener.remove()
    }
    
    
    // MARK: - All friends
    /** The list of all friends of the current user. */
    var friendList = [User]()
    /** Adds a friend observer. The completion function will run every time this list changes, allowing you
     to update your UI. */
    func addFriendObserver(_ update: @escaping () -> Void) {
        CURRENT_USER_FRIENDS_REF.observe(DataEventType.value, with: { (snapshot) in
            self.friendList.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                self.getUser(id, completion: { (user) in
                    self.friendList.append(user)
                    update()
                })
            }
            // If there are no children, run completion here instead
            if snapshot.childrenCount == 0 {
                update()
            }
        })
    }
    /** Removes the friend observer. This should be done when leaving the view that uses the observer. */
    func removeFriendObserver() {
        CURRENT_USER_FRIENDS_REF.removeAllObservers()
    }
    
    
    
    // MARK: - All requests
    /** The list of all friend requests the current user has. */
    var requestList = [User]()
    /** Adds a friend request observer. The completion function will run every time this list changes, allowing you
     to update your UI. */
    func addRequestObserver(_ update: @escaping () -> Void) {
        CURRENT_USER_REQUESTS_REF.observe(DataEventType.value, with: { (snapshot) in
            self.requestList.removeAll()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let id = child.key
                self.getUser(id, completion: { (user) in
                    self.requestList.append(user)
                    update()
                })
            }
            // If there are no children, run completion here instead
            if snapshot.childrenCount == 0 {
                update()
            }
        })
    }
    /** Removes the friend request observer. This should be done when leaving the view that uses the observer. */
    func removeRequestObserver() {
        CURRENT_USER_REQUESTS_REF.remove()
    }
    
}




