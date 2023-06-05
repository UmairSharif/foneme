//
//  ViewController.swift
//  TTGTagSwiftExample
//
//  Created by zekunyan on 2021/4/30.
//

import UIKit

class CategoryVC: UIViewController {
    @IBOutlet weak var skillTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var tableData = [Category]()
    var categoryData = [Category]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCategory()
        skillTableView.register(UINib(nibName: "CategoryTableViewCell", bundle: nil), forCellReuseIdentifier: "category")
    }
    
    func loadCategory() {
        guard let urlPath = Bundle.main.path(forResource: "categories", ofType: "json") else {
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: urlPath))
            self.categoryData = try JSONDecoder().decode([Category].self, from: data)
            self.tableData = self.categoryData
            skillTableView.reloadData()
        } catch {
            return
        }
    }
    
    @IBAction func tapDone(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension CategoryVC: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText.count > 0 else {
            self.tableData = categoryData
            skillTableView.reloadData()
            return
        }
        
        var tableData = [Category]()
        
        categoryData.forEach { category in
            let newCategory = Category(id: category.id, name: category.name, subcategories: [])
            
            let subcategories = category.subcategories.filter { subcategory in
                return subcategory.name.lowercased()
                    .range(of: searchText.lowercased()) != nil
            }
            
            if subcategories.count > 0 {
                newCategory.subcategories = subcategories
                tableData.append(newCategory)
            }
        }
        
        self.tableData = tableData
        skillTableView.reloadData()
    }
}

extension CategoryVC: UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "category") as? CategoryTableViewCell
        
        if let cell {
            let category = tableData[indexPath.row]
            cell.resetCell(category: category)
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
}

