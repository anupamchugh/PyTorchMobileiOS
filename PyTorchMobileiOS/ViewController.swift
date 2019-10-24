//
//  ViewController.swift
//  PyTorchMobileiOS
//
//  Created by Anupam Chugh on 24/10/19.
//  Copyright © 2019 Anupam Chugh. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imageView: UIImageView?
    var button: UIButton?
    var predictionLabel : UILabel?
    
    let inputSize = CGSize(width: 224, height: 224)
    
    
    private lazy var module: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "mobilenet-v2", ofType: "pt"),
            let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()
    
    private lazy var labels: [String] = {
        if let filePath = Bundle.main.path(forResource: "labels", ofType: "txt"),
            let labels = try? String(contentsOfFile: filePath) {
            return labels.components(separatedBy: .newlines)
        } else {
            fatalError("Can't find the text file!")
        }
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        buildUI()
        button?.addTarget(self, action: #selector(showActionSheet(sender:)), for: .touchUpInside)
        
    }
    
    func buildUI()
    {
        
        imageView = UIImageView(frame: .zero)
        imageView?.image = UIImage(named: "placeholder")
        imageView?.contentMode = .scaleAspectFit
        imageView?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(imageView!)
        
        let aspectRatio = NSLayoutConstraint(item: imageView!, attribute: .width, relatedBy: .equal, toItem: imageView!, attribute: .height, multiplier: 1.0, constant: 0)
        
        NSLayoutConstraint.activate([
            imageView!.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView!.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            imageView!.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            aspectRatio
        ])
        
        button = UIButton(type: .system)
        button?.setTitle("Select Image", for: .normal)
        button?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(button!)
        
        
        NSLayoutConstraint.activate([
            button!.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            button!.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 20),
            button!.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20),
            button!.heightAnchor.constraint(equalToConstant: 50)
            
        ])
        
        predictionLabel = UILabel(frame: .zero)
        predictionLabel?.numberOfLines = 0
        predictionLabel?.textAlignment = .center
        predictionLabel?.text = "Prediction will be displayed here.."
        predictionLabel?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(predictionLabel!)
        
        NSLayoutConstraint.activate([
            predictionLabel!.bottomAnchor.constraint(equalTo: self.button!.topAnchor, constant: -20),
            predictionLabel!.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 20),
            predictionLabel!.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20),
            predictionLabel!.topAnchor.constraint(equalTo: self.imageView!.bottomAnchor, constant: 20),
            
        ])
    }
    
    
    @objc func showActionSheet(sender: UIButton)
    {
        let alert = UIAlertController(title: "Select Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.launchCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Photos Library", style: .default, handler: { _ in
            self.showPhotosLibrary()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            alert.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func launchCamera()
    {
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
        else{
            let alert  = UIAlertController(title: "Warning", message: "There's no camera.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showPhotosLibrary(){
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                self.imageView?.image = image
                self.predictImage(image: image)
                
            }
        }
    }
    
    func predictImage(image: UIImage){
        let resizedImage = image.resized(to: inputSize)
        guard var pixelBuffer = resizedImage.normalized() else {
            return
        }
        
        let outputIndex = module.predict(image: UnsafeMutableRawPointer(&pixelBuffer), labelCount: labels.count)
        if outputIndex > 0{
            predictionLabel?.text = "Prediction is: \(labels[outputIndex])"
        }
        else{
            predictionLabel?.text = "No Output"
        }
        
    }
    
    
    
}

