//
//  DetailViewController.swift
//  StoreSearch
//
//  Created by zijie vv on 15/04/2019.
//  Copyright © 2019 zijie vv. All rights reserved.
//

import UIKit
import MessageUI


class DetailViewController: UIViewController {
    enum AnimationStyle {
        case slide
        case fade
    }
    
    @IBOutlet weak var popupView:UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var kindLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var priceButton: UIButton!
    
    var searchResult: SearchResult! {
        didSet {
            if isViewLoaded {
                updateUI()
            }
        }
    }
    var downloadTask: URLSessionDownloadTask?
    var dismissStyle = AnimationStyle.fade
    var isPopUp = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.tintColor = UIColor(red: 20/255,
//                                 green: 160/255,
//                                 blue: 160/255,
//                                 alpha: 1)
//        view.tintColor = UIColor(red: 0/255,
//                                 green: 122/255,
//                                 blue: 255/255,
//                                 alpha: 1)
//        view.tintColor = UIColor(red: 76/255,
//                                 green: 217/255,
//                                 blue: 100/255,
//                                 alpha: 1)
        view.tintColor = UIColor(red: 90/255,
                                 green: 200/255,
                                 blue: 250/255,
                                 alpha: 1)
        popupView.layer.cornerRadius = 10
        
//        let gestureRecognizer = UITapGestureRecognizer(target: self,
//                                                       action: #selector(close))
//        gestureRecognizer.cancelsTouchesInView = false
//        gestureRecognizer.delegate = self
//        view.addGestureRecognizer(gestureRecognizer)
        if isPopUp {
            let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                           action: #selector(close))
            gestureRecognizer.cancelsTouchesInView = false
            gestureRecognizer.delegate = self
            view.addGestureRecognizer(gestureRecognizer)
            
            view.backgroundColor = UIColor.clear
        } else {
            view.backgroundColor = UIColor(
                patternImage: UIImage(named: "LandscapeBackground")!)
            popupView.isHidden = true
            
            if let displayName =
                Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"]
                    as? String {
                title = displayName
            }
        }
        
        if searchResult != nil {
            updateUI()
        }
        
//        view.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    deinit {
        print("deinit \(self)")
        downloadTask?.cancel()
    }
    
    // MARK:- Actions
    @IBAction func close() {
        dismissStyle = .slide
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func openInStore() {
        if let url = URL(string: searchResult.storeURL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowMenu" {
            let controller = segue.destination as! MenuViewController
            controller.delegate = self
        }
    }

    // MARK:- UI
    func updateUI() {
        nameLabel.text = searchResult.name
        
        if searchResult.artist.isEmpty {
            artistNameLabel.text = NSLocalizedString(
                "Unknown",
                comment: "Artist Name Label: Unknown")
        } else {
            artistNameLabel.text = searchResult.artist
        }
        
        kindLabel.text = searchResult.type
        genreLabel.text = searchResult.genre
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = searchResult.currency
        
        let priceText: String
        
        if searchResult.price == 0 {
            priceText = "Free"
        } else if let text = formatter.string(from: searchResult.price as NSNumber) {
            priceText = text
        } else {
            priceText = ""
        }
        
        priceButton.setTitle(priceText, for: .normal)
        
        if let largeURL = URL(string: searchResult.imageLarge) {
            downloadTask = artworkImageView.loadImage(url: largeURL)
        }
        
        popupView.isHidden = false
    }

}

extension DetailViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController)
    -> UIPresentationController? {
        return DimmingPresentationController(presentedViewController: presented,
                                             presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        return BounceAnimationController()
    }
    
    func animationController(
        forDismissed dismissed: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        switch dismissStyle {
        case .slide:
            return SlideOutAnimationController()
        case .fade:
            return FadeOutAnimationController()
        }
    }
    
}

extension DetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view)
    }
    
}

extension DetailViewController: MenuViewControllerDelegate {
    func menuViewControllerSendEmail(_ controller: MenuViewController) {
        if MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.mailComposeDelegate = self
            
            controller.setSubject(
                NSLocalizedString("Support Request", comment: "Email subject"))
            controller.setToRecipients(["your@email-address-here.com"])
            controller.modalPresentationStyle = .formSheet
            
            self.present(controller, animated: true, completion: nil)
        }
    }
}

extension DetailViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}

