//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by zijie vv on 16/04/2019.
//  Copyright © 2019 zijie vv. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    private var firstTime = true
    private var downloads = [URLSessionDownloadTask]()
//    var searchResults = [SearchResult]()
    var search: Search!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove constraints from main view
        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true
        
        // Remove constraints for page control
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        
        // Remove constraints for scroll view
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        
        view.backgroundColor = UIColor(
            patternImage: UIImage(named: "LandscapeBackground")!)
//        scrollView.contentSize = CGSize(width: 1000, height: 1000)
        
        pageControl.numberOfPages = 0
    }
    
    // MARK:- Actions
    @IBAction func pageChanged(_ sender: UIPageControl) {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                self.scrollView.contentOffset = CGPoint(
                    x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage),
                    y: 0)
            },
            completion: nil)
        
        scrollView.contentOffset = CGPoint(
            x: scrollView.bounds.size.width * CGFloat(sender.currentPage),
            y: 0)
    }
    
    // MARK:- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            if case .results(let list) = search.state {
                let detailViewController = segue.destination as! DetailViewController
                let searchResult = list[(sender as! UIButton).tag - 2000]
                detailViewController.searchResult = searchResult
                detailViewController.isPopUp = true
            }
        }
    }
    
    // MARK:- objc
    @objc func buttonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowDetail", sender: sender)
    }
    
    
    // MARK:- overrides
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let safeFrame = view.safeAreaLayoutGuide.layoutFrame
        scrollView.frame = safeFrame
        pageControl.frame = CGRect(
            x: safeFrame.origin.x,
            y: safeFrame.size.height - pageControl.frame.size.height,
            width: safeFrame.size.width,
            height: pageControl.frame.size.height)
        
        if firstTime {
            firstTime = false
//            tileButtons(search.searchResults)
            switch search.state {
            case .notSearchedYet:
                break
            case .loading:
                showSpinner()
            case .noResults:
                showNothingFoundLabel()
            case .results(let list):
                tileButtons(list)
            }
        }
    }
    
    private func tileButtons(_ searchResults: [SearchResult]) {
        var columnsPerpage = 6
        var rowsPerpage = 3
        var itemWidth: CGFloat = 94
        var itemHeight: CGFloat = 88
        var marginX: CGFloat = 2
        var marginY: CGFloat = 20
        
        let viewWidth = scrollView.bounds.size.width
        
        switch viewWidth {
        case 568:
            // for 4-inch device
            break
        case 667:
            // for 4.7-inch device
            columnsPerpage = 7
            itemWidth = 95
            itemHeight = 98
            marginX = 1
            marginY = 29
        case 736:
            // for 5.5-inch device
            columnsPerpage = 8
            rowsPerpage = 4
            itemWidth = 92
            marginX = 0
        case 724:
            // for iPhone X
            columnsPerpage = 8
            rowsPerpage = 3
            itemWidth = 90
            itemHeight = 98
            marginX = 2
            marginY = 29
        default:
            break
        }
        
        // Button size
        let buttonWidth: CGFloat = 82
        let buttonHeight: CGFloat = 82
        let paddingHorz = (itemWidth - buttonWidth) / 2
        let paddingVert = (itemHeight - buttonHeight) / 2
        
        var row = 0
        var column = 0
        var x = marginX
        
        for (index, result) in searchResults.enumerated() {
            let button = UIButton(type: .custom)
            downloadImage(for: result, adnPlaceOn: button)
            button.tag = 2000 + index
            button.addTarget(self,
                             action: #selector(buttonPressed),
                             for: .touchUpInside)
            button.setBackgroundImage(UIImage(named: "LandscapeButton"), for: .normal)
//            let button = UIButton(type: .system)
            button.backgroundColor = UIColor.white
            button.setTitle("\(index)", for: .normal)
            button.frame = CGRect(
                x: x + paddingHorz,
                y: marginY + CGFloat(row) * itemHeight + paddingVert,
                width: buttonWidth,
                height: buttonHeight)
            scrollView.addSubview(button)
            
            row += 1
            
            if row == rowsPerpage {
                row = 0
                x += itemWidth
                column += 1
                
                if column == columnsPerpage {
                    column = 0
                    x += marginX * 2
                }
            }
        }
        
        // Set scroll view content size
        let buttonsPerpage = columnsPerpage * rowsPerpage
        let numPages = 1 + (searchResults.count - 1) / buttonsPerpage
        
        scrollView.contentSize = CGSize(width: CGFloat(numPages) * viewWidth,
                                        height: scrollView.bounds.size.height)
        
        print("Number of pages: \(numPages)")
        
        pageControl.numberOfPages = numPages
        pageControl.currentPage = 0
    }
    
    private func downloadImage(for searchResult: SearchResult, adnPlaceOn button: UIButton) {
        if let url = URL(string: searchResult.imageSmall) {
            let task = URLSession.shared.downloadTask(with: url) {
                [weak button] url, response, error in
                
                if error == nil,
                let url = url,
                let data = try? Data(contentsOf: url),
                let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let button = button {
                            button.setImage(image, for: .normal)
                        }
                    }
                }
            }
            
            task.resume()
            downloads.append(task)
        }
    }
    
    private func showSpinner() {
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.center = CGPoint(x: scrollView.bounds.midX + 0.5,
                                 y: scrollView.bounds.midY + 0.5)
        spinner.tag = 1000
        view.addSubview(spinner)
        spinner.startAnimating()
    }
    
    private func hideSpinner() {
        view.viewWithTag(1000)?.removeFromSuperview()
    }
    
    private func showNothingFoundLabel() {
        let label = UILabel(frame: CGRect.zero)
        label.text = NSLocalizedString(
            "Nothing Found",
            comment: "Show Nothing Found Label: Nothing Found")
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.clear
        
        label.sizeToFit()
        
        var rect = label.frame
        rect.size.width = ceil(rect.size.width / 2) * 2
        rect.size.height = ceil(rect.size.height / 2) * 2
        label.frame = rect
        
        label.center = CGPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY)
        
        view.addSubview(label)
    }
    
    // MARK:- Public methods
    func searchResultsReceived() {
        hideSpinner()
        
        switch search.state {
        case .notSearchedYet, .loading:
            break
        case .noResults:
            showNothingFoundLabel()
        case .results(let list):
            tileButtons(list)
        }
    }

}

extension LandscapeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        let page = Int((scrollView.contentOffset.x + width / 2) / width)
        pageControl.currentPage = page
    }
    
}

