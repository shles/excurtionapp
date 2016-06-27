//
//  PhotoListViewController.swift
//  ExcurtionApp
//
//  Created by Артмеий Шлесберг on 26/06/16.
//  Copyright © 2016 Shlesberg. All rights reserved.
//

import Foundation
import UIKit
import ParseUI
import Haneke

class PhotoListViewController : UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var objects : [PFObject] = []
    var pointId : String!
    var heights : [CGFloat] = []
    
    var imgPicker : UIImagePickerController = UIImagePickerController()
    
    
    override func viewDidLoad() {
        let q = PFQuery(className: "Photo" )
        q.whereKey("pointId", equalTo: pointId)
        
        q.findObjectsInBackgroundWithBlock { objects, error in
            self.objects = objects!
            
            for _ in objects! {
                self.heights.append(50)
            }
            
            self.tableView.reloadData()
            
            
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(addPhoto))
        imgPicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imgPicker.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        imgPicker.delegate = self
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("photo", forIndexPath: indexPath) as! PhotoCell
        
        cell.photo.image = nil
        
        
        let object = objects[indexPath.row]
        let file = object["image"] as? PFFile
        let format  = Format<UIImage>(name: "photo")
        
        cell.photo.hnk_setImageFromURL(NSURL(string:  (file?.url)!)!, placeholder: nil, format: format, failure: nil) { image in
            
            cell.photo.image = image
            let height = self.getHightForImage(image)
            self.heights[indexPath.row] = height

            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if heights.count > indexPath.row {
            return heights[indexPath.row]
        }
        return 50.0
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        let obj = PFObject(className: "Photo")
        
        
        obj["image"] = PFFile(data:  UIImageJPEGRepresentation(image, 0.5)!)
        obj["pointId"] = self.pointId
        obj.saveInBackgroundWithBlock { (res, error) -> Void in
            self.objects.append(obj)
            
            let height = self.getHightForImage(image)
            self.heights.append(height)
            
            self.tableView.reloadData()
        }
        
        dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    func addPhoto() {
        presentViewController(imgPicker, animated: true) { () -> Void in
            
        }
    }
    
    private func getHightForImage(image : UIImage) -> CGFloat{
        let height = image.size.height
        let width = image.size.width
        
        let ratio =  self.view.frame.size.width/width
        return height * ratio
    }
    
}

class PhotoCell : PFTableViewCell {
    
    @IBOutlet weak var photo: UIImageView!
}