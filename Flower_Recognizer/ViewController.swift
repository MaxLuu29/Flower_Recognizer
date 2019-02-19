//
//  ViewController.swift
//  Flower_Recognizer
//
//  Created by D@ on 2/1/19.
//  Copyright © 2019 Max Luu. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var displayViewImage: UIImageView!
    let imagePicker = UIImagePickerController()
    let wikiAPI_URL = "https://en.wikipedia.org/w/api.php"
    @IBOutlet weak var flowerDescriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[.editedImage] as? UIImage {
            displayViewImage.image = userPickedImage
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("unable to convert UIImage into CIImage")
            }
            
            detect(flowerImage: ciImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(flowerImage: CIImage) {
        guard let mlModel = try? VNCoreMLModel(for: FlowerMLClassifier().model) else {
            fatalError("loading coreML model failed")
        }
        let MLrequest = VNCoreMLRequest(model: mlModel) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("model failed to process image")
            }
            
            if let highestResult = results.first {
                self.navigationItem.title = highestResult.identifier.capitalized
                self.httpQuery(flowerName: highestResult.identifier)
            }
        }
        
        let requestHandler = VNImageRequestHandler(ciImage: flowerImage)
        do {
            try requestHandler.perform([MLrequest])
        } catch {
            print(error)
        }
    }
    
    func httpQuery(flowerName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikiAPI_URL, method: .get, parameters: parameters).responseJSON { (results) in
            if results.result.isSuccess {
                let JSON_data = JSON(results.result.value!)
                print(JSON_data)
                
                let pageID = JSON_data["query"]["pageids"][0].stringValue
                let flowerDescription = JSON_data["query"]["pages"][pageID]["extract"].stringValue
                print(flowerDescription)
                
                let imageURL = JSON_data["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                
                self.displayViewImage.sd_setImage(with: URL(string: imageURL))
                self.flowerDescriptionLabel.text = flowerDescription
            }
        }
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
}

