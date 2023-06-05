//
//  OpenChannelsViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/16/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import AlamofireImage
import SVProgressHUD

class OpenChannelsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, CreateOpenChannelDelegate, OpenChanannelChatDelegate, NotificationDelegate {
    @IBOutlet weak var openChannelsTableView: UITableView!
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var toastView: UIView!
    @IBOutlet weak var toastMessageLabel: UILabel!
    
    private var channels: [SBDOpenChannel] = []
    private var refreshControl: UIRefreshControl?
    private var searchController: UISearchController?
    private var channelListQuery: SBDOpenChannelListQuery?
    private var channelNameFilter: String?
    private var createChannelBarButton: UIBarButtonItem?
    private var toastCompleted: Bool = true
    private var pendingRequestWorkItem: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = ""
        self.navigationController?.title = ""
        self.navigationItem.largeTitleDisplayMode = .automatic
        
        self.createChannelBarButton = UIBarButtonItem(image: UIImage(named: "img_btn_create_public_group_channel_blue"), style: .plain, target: self, action: #selector(OpenChannelsViewController.clickCreateOpenChannel(_:)))
        
        self.openChannelsTableView.delegate = self
        self.openChannelsTableView.dataSource = self
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(OpenChannelsViewController.refreshChannelList), for: .valueChanged)
        
        self.openChannelsTableView.refreshControl = self.refreshControl
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressChannel(_:)))
        longPressGesture.minimumPressDuration = 1.0
        self.openChannelsTableView.addGestureRecognizer(longPressGesture)
        
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController?.searchBar.delegate = self
        if #available(iOS 13.0, *) {
            self.searchController?.searchBar.searchTextField.textColor = UIColor.white
        } else {
            // Fallback on earlier versions
        }
        self.searchController?.searchBar.placeholder = "Public Chat Name"
        self.searchController?.obscuresBackgroundDuringPresentation = false
        self.searchController?.searchBar.tintColor = hexStringToUIColor(hex: "0072F8")
        self.searchController?.searchBar.showsCancelButton = false
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = true
        
        self.searchController?.hidesNavigationBarDuringPresentation = false
        self.searchController?.isActive = true
        self.loadingIndicatorView.isHidden = true
        self.searchController?.searchBar.set(textColor: .black)
        self.searchController?.searchBar.setTextField(color: .white)
        self.openChannelsTableView.keyboardDismissMode = .onDrag
        refreshChannelList()
    }
    
    func showToast(message: String, completion: (() -> Void)?) {
        self.toastCompleted = false
        self.toastView.alpha = 1
        self.toastMessageLabel.text = message
        self.toastView.isHidden = false
        
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseIn, animations: {
            self.toastView.alpha = 0
        }) { (finished) in
            self.toastView.isHidden = true
            self.toastCompleted = true
            
            completion?()
        }
    }
    
    @objc func longPressChannel(_ recognizer: UILongPressGestureRecognizer) {
        let point = recognizer.location(in: self.openChannelsTableView)
        guard let indexPath = self.openChannelsTableView.indexPathForRow(at: point) else { return }
        if recognizer.state == .began {
            let channel = self.channels[indexPath.row]
            let alert = UIAlertController(title: channel.name, message: nil, preferredStyle: .actionSheet)
            
            let actionReport = UIAlertAction(title: "Report", style: .default) { (action) in
                self.showConfirmDialog("Report", "Are you sure you want to report this channel?") {
                    self.showToast(message: "Reported", completion: nil)
                }
            }
            
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.modalPresentationStyle = .popover
            alert.addAction(actionReport)
            alert.addAction(actionCancel)
            
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = self.view
                presenter.sourceRect = CGRect(x: self.view.bounds.minX, y: self.view.bounds.maxY, width: 0, height: 0)
                presenter.permittedArrowDirections = []
            }
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func setUp(navCont:UINavigationController){
        
        navCont.navigationBar.tintColor = UIColor.white;
        navCont.navigationBar.barTintColor = hexStringToUIColor(hex: "0072F8")
        navCont.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white,
                                                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 21, weight: .medium)]
        navCont.navigationBar.isTranslucent = false
        navCont.navigationBar.prefersLargeTitles = false
        
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowOpenChat", let navigation = segue.destination as? UINavigationController, let destination = navigation.children.first as? OpenChannelChatViewController, let selectedChannel = sender as? SBDOpenChannel{
            destination.channel = selectedChannel
            destination.hidesBottomBarWhenPushed = true
            destination.delegate = self
            self.setUp(navCont: navigation)
        } else if segue.identifier == "CreateOpenChannel", let destination = segue.destination as? CreateOpenChannelNavigationController{
            destination.createChannelDelegate = self
        }
    }
    
    @objc func clickCreateOpenChannel(_ sender: AnyObject) {
        performSegue(withIdentifier: "CreateOpenChannel", sender: nil)
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        (navigationController?.parent as? UITabBarController)?.selectedIndex = 0
        
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelTableViewCell") as! OpenChannelTableViewCell
        cell.channel = self.channels[indexPath.row]
        /// Load more
        if self.channels.count > 0 && indexPath.row == self.channels.count - 1 {
            self.loadChannelListNextPage(refresh: false, channelNameFilter: self.channelNameFilter)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.channelNameFilter == nil {
            self.emptyLabel.text = "There are no public chat"
        } else {
            self.emptyLabel.text = "Search results not found"
        }
        self.emptyLabel.isHidden = !(self.channels.count == 0)
        return self.channels.count
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedChannel = self.channels[indexPath.row]
        if self.splitViewController?.displayMode == UISplitViewController.DisplayMode.allVisible {
            
        }
        SVProgressHUD.show()
        
        selectedChannel.enter { (error) in
            SVProgressHUD.dismiss()
            
            if let error = error {
                debugPrint(error.localizedDescription)
                //Utils.showAlertController(error: error, viewController: self)
                return
            }
            
            self.performSegue(withIdentifier: "ShowOpenChat", sender: selectedChannel)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: - Load channels
    @objc func refreshChannelList() {
        self.loadChannelListNextPage(refresh: true, channelNameFilter: self.channelNameFilter)
    }
    
    func clearSearchFilter() {
        self.searchController?.searchBar.resignFirstResponder()
        self.channelNameFilter = nil
        refreshChannelList()
    }
    
    func loadChannelListNextPage(refresh: Bool, channelNameFilter: String?) {
        if refresh {
            self.channelListQuery = nil
        }
        
        if self.channelListQuery == nil {
            self.channelListQuery = SBDOpenChannel.createOpenChannelListQuery()
            self.channelListQuery?.limit = 20
            if (channelNameFilter?.count ?? 0 ) > 0 {
                self.channelListQuery?.channelNameFilter = channelNameFilter
            }
        }
        
        if self.channelListQuery?.hasNext == false {
            return
        }
        SVProgressHUD.show()
        self.channelListQuery?.loadNextPage(completionHandler: { (channels, error) in
            
            DispatchQueue.main.async {
                if error != nil {
                    self.refreshControl?.endRefreshing()
                    return
                }
                
                if refresh {
                    self.channels.removeAll()
                }
                
                channels?.forEach({ channel in
                    if !channel.name.isEmpty {
                        self.channels.append(channel)
                    }
                })
                self.openChannelsTableView.reloadData()
                self.refreshControl?.endRefreshing()
                SVProgressHUD.dismiss()
            }
        })
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        pendingRequestWorkItem?.cancel()
        
        let requestWorkItem = DispatchWorkItem { [unowned self] in
            self.channelNameFilter = searchText
            self.refreshChannelList()
        }
        
        pendingRequestWorkItem = requestWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250),
                                      execute: requestWorkItem)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.channelNameFilter = nil
        self.refreshChannelList()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.channelNameFilter = searchBar.text
        self.refreshChannelList()
    }
    
    // MARK: - CreateOpenChannelDelegate
    func didCreate(_ channel: SBDOpenChannel) {
        self.channelNameFilter = nil
        
        self.refreshChannelList()
    }
    
    // MARK: - OpenChannelChatDelegate
    func didUpdateOpenChannel() {
        DispatchQueue.main.async {
            self.openChannelsTableView.reloadData()
        }
    }
}
