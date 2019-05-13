import UIKit
import MobileCoreServices
import Alamofire
import Foundation

class ViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var cameraButton: UIButton!
    
    let processor = ScaledElementProcessor()
    var frameSublayer = CALayer()

    var scannedText: String = "Detected text can be edited here." {
        didSet {
            textView.text = scannedText
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.delegate = self
        
        

        // Notifications to slide the keyboard up
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        imageView.layer.addSublayer(frameSublayer)
        drawFeatures(in: imageView)
        
        
        
        
        
    }
    
    // MARK: Touch handling to dismiss keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        
        
    }
    
    // MARK: Actions
    @IBAction func cameraDidTouch(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            presentImagePickerController(withSourceType: .camera)
        } else {
            let alert = UIAlertController(title: "Camera Not Available", message: "A camera is not available. Please try picking an image from the image library instead.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func libraryDidTouch(_ sender: UIButton) {
        presentImagePickerController(withSourceType: .photoLibrary)
    }
    
    @IBAction func shareDidTouch(_ sender: UIBarButtonItem) {
        let vc = UIActivityViewController(activityItems: [scannedText, imageView.image!], applicationActivities: [])
        present(vc, animated: true, completion: nil)
        
    }
    
    // MARK: Keyboard slide up
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
                view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y != 0 {
                view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    //Submit button
    
    
    @IBAction func submit(_ sender: Any) {
        if textView.text.isEmpty==true{
            let alert = UIAlertController(title: "Please enter Text to Submit!", message: "Cannot submit an empty response!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
            
            
            
        else{let alert = UIAlertController(title: "Result Submitted", message: "The response has been recorded sucessfully!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true)
            textView.text="Detected text can be edited here.";}
    }
    
    
   
    @IBAction func onSend(_ sender: Any) {
        let alert = UIAlertController(title: "The Image has been sent to our Backend!", message: "Please wait for the response. This might take a while!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true)
        let errorClosure = { (error: Error?) in
            self.textView.text="  "
            
        }
        let data = imageView.image?.jpegData(compressionQuality: 0.85)
        
        requestWith(imageData: data, parameters: [:], onError: errorClosure)
    }
    
   
    
    
    
    
    private func removeFrames() {
        guard let sublayers = frameSublayer.sublayers else { return }
        for sublayer in sublayers {
            sublayer.removeFromSuperlayer()
        }
    }
    
    // 1
    private func drawFeatures(in imageView: UIImageView, completion: (() -> Void)? = nil) {
        removeFrames()
        processor.process(in: imageView) { text, elements in
            elements.forEach() { element in
                self.frameSublayer.addSublayer(element.shapeLayer)
            }
            self.scannedText = text
            completion?()
        }
    }
}




extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {
    // MARK: UIImagePickerController
    
    private func presentImagePickerController(withSourceType sourceType: UIImagePickerController.SourceType) {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.sourceType = sourceType
        controller.mediaTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: UIImagePickerController Delegate
    
    
    
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage =
            info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            imageView.contentMode = .scaleAspectFit
            let fixedImage = pickedImage.fixOrientation()
            imageView.image = fixedImage
            drawFeatures(in: imageView)
        }
        dismiss(animated: true, completion: nil)
    }
    func requestWith(imageData: Data?, parameters: [String : Any], onError: ((Error?) -> Void)? = nil){
        
        let url = "http://3.18.109.255:8000/ReceiveImage/" /* your API url */
        
        let headers: HTTPHeaders = [
            /* "Authorization": "your_access_token",  in case you need authorization header */
            "Content-type": "multipart/form-data"
        ]
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            for (key, value) in parameters {
                multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
            }
            
            if let data = imageData{
                multipartFormData.append(data, withName: "image", fileName: "image.png", mimeType: "image/png")
            }
            
        }, usingThreshold: UInt64.init(), to: url, method: .post, headers: headers) { (result) in
            switch result{
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    print("Succesfully uploaded")
                    if let err = response.error{
                        onError?(err)
                        return
                    }
                    if let result = response.result.value {
                        let json = result as! NSDictionary
                        let TrimInfo = json["Trim_Information"]
                        print("Here")
                        print(result)
                        //                      let a = TrimInfo.components(separatedBy:",")
                        self.textView.text=TrimInfo as? String;
                    }
                    //onCompletion?(nil)
                }
            case .failure(let error):
                print("Error in upload: \(error.localizedDescription)")
                onError?(error)
            }
        }
    }
}
