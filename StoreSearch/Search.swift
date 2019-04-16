//
//  Search.swift
//  StoreSearch
//
//  Created by zijie vv on 16/04/2019.
//  Copyright © 2019 zijie vv. All rights reserved.
//

import Foundation
import UIKit


typealias SearchComplete = (Bool) -> Void

class Search {
    enum Category: Int {
        case all = 0
        case music = 1
        case software = 2
        case ebooks = 3
        
        var type: String {
            switch self {
            case .all:
                return ""
            case .music:
                return "musicTrack"
            case .software:
                return "software"
            case .ebooks:
                return "ebooks"
            }
        }
    }
    
//    var searchResults: [SearchResult] = []
//    var hasSearched = false
//    var isLoading = false
    enum State {
        case notSearchedYet
        case loading
        case noResults
        case results([SearchResult])
    }
    
    private(set) var state: State = .notSearchedYet
    
    private var dataTask: URLSessionDataTask? = nil
    
    /* The @escaping annotation is necessary for closures that're not used immdeiately
     * It tells Swift that this closure may need to capture variables such as self
     * and keep them around for a little until the closure can finally be executed,
     * in this case, when the search is done.
     */
    func performSearch(for text: String, category: Category, completion: @escaping SearchComplete) {
        if !text.isEmpty {
            dataTask?.cancel()
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            state = .loading
            
            let url = iTunesURL(searchText: text, category: category)
            
            let session = URLSession.shared
            dataTask = session.dataTask(with: url, completionHandler: {
                data, response, error in
                
                var newState = State.notSearchedYet
                var success = false
                
                if let error = error as NSError?, error.code == -999 {
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200,
                let data = data {
                    var searchResults = self.parse(data: data)
                    
                    if searchResults.isEmpty {
                        newState = .noResults
                    } else {
                        searchResults.sort(by: <)
                        newState = .results(searchResults)
                    }
                    success = true
                }
                
                DispatchQueue.main.async {
                    self.state = newState
                    completion(success)
                }
            })
            
            dataTask?.resume()
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    // MARK: iTunes URL
    private func iTunesURL(searchText: String, category: Category) -> URL {
        let kind: String = category.type
        
        let encodedText = searchText.addingPercentEncoding(
            withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        //        let urlString = String(format: "https://itunes.apple.com/search?term=%@",
        //                               encodedText)
        //        let urlString = String(format: "https://itunes.apple.com/search?term=%@&limit=200", encodedText)
        let urlString = "https://itunes.apple.com/search?" +
        "term=\(encodedText)&limit=200&entity=\(kind)"
        let url = URL(string: urlString)
        
        return url!
    }
    
    private func parse(data: Data) -> [SearchResult] {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ResultArray.self, from: data)
            
            return result.results
        } catch {
            print("JSON Error: \(error)")
            return []
        }
    }
    
}

