//
//  imageFeed.swift
//  snapChatProject
//
//  Created by Akilesh Bapu on 2/27/17.
//  Copyright © 2017 org.iosdecal. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseDatabase


var threads: [String: [Post]] = ["Memes": [], "Dog Spots": [], "Random": []]


let threadNames = ["Memes", "Dog Spots", "Random"]


func getPostFromIndexPath(indexPath: IndexPath) -> Post? {
    let sectionName = threadNames[indexPath.section]
    if let postsArray = threads[sectionName] {
        return postsArray[indexPath.row]
    }
    print("No post at index \(indexPath.row)")
    return nil
}

func addPostToThread(post: Post) {
    threads[post.thread]!.append(post)
}

func clearThreads() {
    threads = ["Memes": [], "Dog Spots": [], "Random": []]
}

/*
    TODO:
    
    Store the data for a new post in the Firebase database.
    Make sure you understand the hierarchy of the Posts tree before attempting to write any data to Firebase!
    Each post node contains the following properties:
    
    - (string) imagePath: corresponds to the location of the image in the storage module. This is already defined for you below.
    - (string) thread: corresponds to which feed the image is to be posted to.
    - (string) username: corresponds to the display name of the current user who posted the image.
    - (string) date: the exact time at which the image is captured as a string
                        - let dateFormat = "yyyy-MM-dd HH:mm:ss.A"

        Note: Firebase doesn't allow us to store Date objects, so we have to represent the date as a string instead. You can do this by creating a DateFormatter object, setting its dateFormat (check Constants.swift for the correct date format!) and then calling dateFormatter.string(from: Date()).
 
    Create a dictionary with these four properties and store it as a new child under the Posts node (you'll need to create a child using an auto ID)
 
    Finally, save the actual data to the storage module by calling the store function below.
 
    Remember, DO NOT USE ACTUAL STRING VALUES WHEN REFERENCING A PATH! YOU SHOULD ONLY USE THE CONSTANTS DEFINED IN CONSTANTS.SWIFT

*/
func addPost(postImage: UIImage, thread: String, username: String) {
    let dbRef = FIRDatabase.database().reference()
    let data = UIImageJPEGRepresentation(postImage, 1.0)! 
    let path = "\(firStorageImagesPath)/\(UUID().uuidString)"
    // Mine below
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat
    let date = dateFormatter.string(from: Date())
    
    let dictionary = [firImagePathNode: path,
                      firThreadNode: thread,
                      firUsernameNode: username,
                      firDateNode: date]
    dbRef.child(firPostsNode).childByAutoId().setValue(dictionary)
    store(data: data, toPath: path)
}

/* Done - stores data. */
func store(data: Data, toPath path: String) {
    let storageRef = FIRStorage.storage().reference()
    storageRef.child(path).put(data, metadata: nil, completion: { (metadata, error) in
        if let error = error {
            print(error)
        }
    } )
}


/*
    TODO:
    
    This function should query Firebase for all posts and return an array of Post objects. 
    You should use the function 'observeSingleEvent' (with the 'of' parameter set to .value) to get a snapshot of all of the nodes under "Posts".
    If the snapshot exists, store its value as a dictionary of type [String:AnyObject], where the string key corresponds to the ID of each post. 
 
    Then, make a query for the user's read posts ID's. In the completion handler, complete the following:   
        - Iterate through each of the keys in the dictionary
        - For each key:
            - Create a new Post object, where Posts take in a key, username, imagepath, thread, date string, and read property. For the read property, you should set it to true if the key is contained in the user's read posts ID's and false otherwise.
            - Append the new post object to the post array.
        - Finally, call completion(postArray) to return all of the posts.
        - If any part of the function fails at any point (e.g. snapshot does not exist or snapshot.value is nil), call completion(nil).
 
    Remember to use constants defined in Constants.swift to refer to the correct path!
 */
func getPosts(user: CurrentUser, completion: @escaping ([Post]?) -> Void) {
    let dbRef = FIRDatabase.database().reference()
    var postArray: [Post] = []
    // Finally, the getPosts function will retrieve all of the posts from Firebase as well as the current user's read post ID's, and then create a Post array where each post's read property is defined by checking if the id is contained in the read posts. For this part, you'll need to nest closures together to make sure everything is performed in order. This function may end up being a bit large, but the specs in the comments should clearly describe what to do.
    dbRef.child(firPostsNode).observeSingleEvent(of: .value, with: { (snapshot) in
        if snapshot.exists() {
            if let dict: [String:AnyObject] = snapshot.value as! [String : AnyObject]? {
                user.getReadPostIDs (completion: { (snaps) in
                    for (key, value) in dict {
                        let postRead = snaps.contains(key)
                        let posting = Post(id: key,
                                           username: value[firUsernameNode] as! String,
                                           postImagePath: value[firImagePathNode] as! String,
                                           thread: value[firThreadNode] as! String,
                                           dateString: value[firDateNode] as! String,
                                           read: postRead)
                        postArray.append(posting)
                    }
                    completion(postArray)
                } )
            } else {
                completion(nil)
            }
        } else {
            completion(nil)
        }
        
        
    } )

}

func getDataFromPath(path: String, completion: @escaping (Data?) -> Void) {
    let storageRef = FIRStorage.storage().reference()
    storageRef.child(path).data(withMaxSize: 5 * 1024 * 1024) { (data, error) in
        if let error = error {
            print(error)
        }
        if let data = data {
            completion(data)
        } else {
            completion(nil)
        }
    }
}


