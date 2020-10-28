import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

class PhotoFilterViewController: UIViewController {

	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var contrastSlider: UISlider!
	@IBOutlet weak var saturationSlider: UISlider!
    @IBOutlet weak var blurSlider: UISlider!
	@IBOutlet weak var imageView: UIImageView!
    
    var originalImage: UIImage? {
        didSet {
            guard let originalImage = originalImage else {
                scaledImage = nil
                return
            }
            
            var scaledSize = imageView.bounds.size
            let scale = imageView.contentScaleFactor // alternatively you could use UIScreen.main.scale
//            let scale: CGFloat = 0.5 // Makes image blurry but performance is amazing
            
            scaledSize.width *= scale
            scaledSize.height *= scale
            
            guard let scaledUIImage = originalImage.imageByScaling(toSize: scaledSize) else {
                scaledImage = nil
                return
            }
            
            scaledImage = CIImage(image: scaledUIImage)
        }
    }
    
    var scaledImage: CIImage? {
        didSet {
            updateImage()
        }
    }
    
    private let context = CIContext()
    private let colorControlsFilter = CIFilter.colorControls()
    private let blurFilter = CIFilter.gaussianBlur()
	
	override func viewDidLoad() {
		super.viewDidLoad()

//        let filter = CIFilter.gaussianBlur()
//        let filter2 = CIFilter(name: "CIColorControls")
//
//        print(filter.attributes)
        
        originalImage = imageView.image
	}
    
    private func presentImagePickerController() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("The photo library is not available.")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        present(imagePicker,animated: true, completion: nil)
    }
    
    private func image(byFiltering inputImage: CIImage) -> UIImage? {
        
        colorControlsFilter.inputImage = inputImage
        colorControlsFilter.saturation = saturationSlider.value
        colorControlsFilter.brightness = brightnessSlider.value
        colorControlsFilter.contrast = contrastSlider.value
        
        blurFilter.inputImage = colorControlsFilter.outputImage?.clampedToExtent()
        blurFilter.radius = blurSlider.value
        
        guard let outputImage = blurFilter.outputImage else { return nil }
        
        guard let renderedCGImage = context.createCGImage(outputImage, from: inputImage.extent) else { return nil }
        
        return UIImage(cgImage: renderedCGImage)
    }
    
    private func updateImage() {
        if let scaledImage = scaledImage {
            imageView.image = image(byFiltering: scaledImage)
        } else {
            imageView.image = nil
        }
    }
	
	// MARK: Actions
	
	@IBAction func choosePhotoButtonPressed(_ sender: Any) {
		// Show the photo picker so we can choose on-device photos
		// UIImagePickerController + Delegate
        presentImagePickerController()
	}
	
	@IBAction func savePhotoButtonPressed(_ sender: UIButton) {
		// Save to photo library
        guard let originalImage = originalImage?.flattened,
              let originalCIImage = CIImage(image: originalImage),
              let processedImage = image(byFiltering: originalCIImage)
        else { return }
        
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: processedImage)
        } completionHandler: { (success, error) in
            if let error = error {
                print("Error saving photo: \(error)")
            }
            
            DispatchQueue.main.async {
                self.presentSuccessfulSaveAlert()
            }
        }
	}
    
    private func presentSuccessfulSaveAlert() {
        let alert = UIAlertController(title: "Photo Saved!", message: "The photo has been saved to your Photo Library!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
	
	// MARK: Slider events
	
	@IBAction func brightnessChanged(_ sender: UISlider) {
        updateImage()
	}
	
	@IBAction func contrastChanged(_ sender: Any) {
        updateImage()
	}
	
	@IBAction func saturationChanged(_ sender: Any) {
        updateImage()
	}
    
    @IBAction func blurChanged(_ sender: Any) {
        updateImage()
    }
}

extension PhotoFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            originalImage = image
        } else if let image = info[.originalImage] as? UIImage {
            originalImage = image
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
