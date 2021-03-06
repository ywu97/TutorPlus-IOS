//
//  SearchViewController.swift
//  Tutor+
//
//  Created by jzhao33 on 10/16/18.
//  Copyright © 2018 JunyiZhao. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    var imageNumber = 0
    
    @IBOutlet var suggestionImageView: [UIImageView]!
    

    @IBOutlet weak var schoolSearchBar: UISearchBar!
    @IBOutlet weak var courseSearchBar: UISearchBar!
    @IBOutlet weak var resultTableView: UITableView!
    
    // Main data source for search Table
    var suggestionTableArray = [String]()
    var currentSuggestionTableArray = [String]()
    var isLastEditedBoxSchool = false
    
    // school and course stores
    var currentSchoolName: String?
    var currentCourseName: String?
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        resultTableView.dataSource = self
        resultTableView.delegate = self
        schoolSearchBar.delegate = self
        courseSearchBar.delegate = self
        
        downloadCollectionInfo()
        initializeImages()
        
    }
    
    // keyboard issue
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return (true)
    }

    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            print("Image Tapped")
            //Here you can initiate your new ViewController
        }
    }
    
    private func initializeImages(){
        let school = FirebaseUser.shared.university
        if school == nil || school == "" { return }
        
        FirebaseTrans.shared.downloadWholeProfileByLimitAndOrder(collections: [FirebaseTrans.USER_COLLECTION],baseField: school!, targetField: FirebaseTrans.COUNT_FIELD, limit: 4, descend: true, completion: {data in
            if var data = data{
                let bound = data.count > 4 ? 4 : data.count
                for i in 0..<bound{
                    if let url = data[i].imageURL, url != ""{
                        FirebaseTrans.shared.downloadImageAndCache(url: url, completion: {image in
                            data[i].image = image
                            self.setRecommendationView(i: i, data: data[i])
                        })
                    }else{
                        self.setRecommendationView(i: i, data: data[i])
                    }
                }
            }
        })
    }
    
    // set recommendation view
    
    func setRecommendationView(i: Int, data: FirebaseUser.ProfileStruct?){
        if let data = data{
            self.suggestionImageView[i].layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            let width = self.suggestionImageView[i].bounds.width
            let height = self.suggestionImageView[i].bounds.height
            let sHeight:CGFloat = 50.0
            let shadow = UIColor.black.withAlphaComponent(0.9).cgColor
            let bottomImageGradient = CAGradientLayer()
            bottomImageGradient.frame = CGRect(x: 0, y: height - sHeight, width: width, height: sHeight)
            bottomImageGradient.colors = [UIColor.clear.cgColor, shadow]
            suggestionImageView[i].layer.insertSublayer(bottomImageGradient, at: 0)
            
            let name = UILabel(frame: CGRect(x: 0, y: 0, width: self.suggestionImageView[i].frame.width - 0,
                                             height: 260))
            name.font = UIFont(name:"HelveticaNeue-Bold", size: 16.0)
            name.textAlignment = NSTextAlignment.center;
            name.textColor = UIColor.white
            name.isUserInteractionEnabled = true
            name.text = data.name
            self.suggestionImageView[i].addSubview(name)
            
            let discription = UILabel(frame: CGRect(x: 0, y: 0, width: self.suggestionImageView[i].frame.width - 0, height: 300))
            discription.textAlignment = NSTextAlignment.center;
            discription.textColor = UIColor.white
            discription.isUserInteractionEnabled = true
            let major = data.major ?? ""
            discription.text = major
            self.suggestionImageView[i].addSubview(discription)
            
            self.suggestionImageView[i].image = data.image
            
            //image tapped
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.imageTapped(gesture:)))
            suggestionImageView[i].addGestureRecognizer(tapGesture)
            suggestionImageView[i].isUserInteractionEnabled = true
        }
    }
    
    
    // Firebase Transmission and overall array manipulation
    
    
    func downloadCollectionInfo(collectionId: String?  = nil){
        var theId = [FirebaseTrans.SCHOOL_COLLECTION]
        
        // if it is to download course collection
        if let id = collectionId{
            theId.append(id)
            theId.append(FirebaseTrans.COURSE_COLLECTION)
        }
        
        // clean current array
        suggestionTableArray = [String]()
        updateSuggestionArray()
        
        FirebaseTrans.shared.downloadAllDocumentIdByCollection(collections: theId, completion: {(data)in
            if let data = data{
                self.suggestionTableArray = data
                self.updateSuggestionArray()
            }
        })
    }
    
    private func updateSuggestionArray(){
        currentSuggestionTableArray = suggestionTableArray
        resultTableView.reloadData()
    }
    
    // ------------------------------------------------------------------------------------
    // Suggestion Table View
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentSuggestionTableArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell") as? SearchViewTableViewCell else {
            debugHelpPrint(type: .SearchViewController, str: "Empty")
            return UITableViewCell()
        }
        cell.suggestionLabel.text = currentSuggestionTableArray[indexPath.row]
        debugHelpPrint(type: .SearchViewController, str: "\(String(describing: cell.suggestionLabel.text))")
        return cell
    }
    
    // user click the item
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let currentCell = tableView.cellForRow(at: indexPath) as? SearchViewTableViewCell
        debugHelpPrint(type: .SearchViewController, str: "\(String(describing: currentCell?.suggestionLabel.text))")
        
        
        if isLastEditedBoxSchool{
            // are we choosing school?
            
            schoolSearchBar.text = currentCell?.suggestionLabel.text
            // setup datastore
            currentSchoolName = currentCell?.suggestionLabel.text
            currentCourseName = nil
            downloadCollectionInfo(collectionId: String(currentSuggestionTableArray[indexPath.row]))
            debugHelpPrint(type: .SearchViewController, str: "Selected school:\(currentSchoolName ?? "null")")
            
        } else {
            // are we choosing course?
            
            courseSearchBar.text = currentCell?.suggestionLabel.text
            currentCourseName = currentCell?.suggestionLabel.text
            debugHelpPrint(type: .SearchViewController, str: "Selected course:\(currentCourseName ?? "null")")
            
            // data for transfer
            var data = Dictionary<String, String>()
            data["school"] = currentSchoolName
            data["course"] = currentCourseName
            
            // here we got both school name and course name
            self.performSegue(withIdentifier: "SearchToResult", sender: data)
        }
        
        resultTableView.isHidden = true
    }
    
    // ------------------------------------------------------------------------------------
    // Search Bars
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        guard !searchText.isEmpty else {
            if (searchBar == schoolSearchBar){downloadCollectionInfo()}
            
            resultTableView.isHidden = true
            currentSuggestionTableArray = suggestionTableArray
            return
        }
        
        isLastEditedBoxSchool = searchBar == schoolSearchBar ? true : false
        
        resultTableView.isHidden = false
        currentSuggestionTableArray = suggestionTableArray.filter({ suggestion -> Bool in
            suggestion.lowercased().contains(searchText.lowercased())
        })
        resultTableView.reloadData()
    }
    
    // ------------------------------------------------------------------------------------
    // Other
    
    // override segue to pass data
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "SearchToResult"){
            let nav = segue.destination as! UINavigationController
            let dest = nav.viewControllers.first as! SearchResultController
            let schoolCourse = sender as! [String:String]
            dest.schoolCourse = schoolCourse
        }
    }
}
