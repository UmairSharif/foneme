//
//  OMServerInteraction.swift
//  OneMinute
//
//  Created by Shan Shafiq on 4/1/17.
//  Copyright © 2017 azantech. All rights reserved.
//
import Foundation
import UIKit
import SwiftyJSON
import Alamofire

struct APIManager {
    static let sharedManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
              configuration.timeoutIntervalForRequest = 120
        return SessionManager(configuration: configuration)
    }()
}


class ServerCall {
	
	static let boundaryConstant = "myRandomBoundary12345"
    
	// MARK: ServerCalls
    class func makeCallWitoutFile(_ url: String, params: [String:Any]?, type:Method, currentView: UIView?,header:[String:String], completionHandler: @escaping (_ response: JSON?) -> ()) {
        self.makeCallWithFile(url, params:params, files: nil, type: type, currentView: currentView, header: header, completionHandler: completionHandler)
	}
    class func makeCallWithFile(_ url: String, params: [String:Any]?, files: [String:OMFile]?, type:Method, currentView: UIView?, header:[String:String],completionHandler: @escaping (_ response: JSON?) -> ()) {
		
		var completeUrl = url
		if url.range(of: "https:") != nil || url.range(of: "http:") != nil{
			completeUrl = url
		}
        print(completeUrl)
        
        if let files = files {
            
            uploadFiles(url, params: params, files: files, currentView: currentView, header: header, completionHandler: { (response) -> () in
                completionHandler(response)
            })
            return
        }
       // print(header)
        APIManager.sharedManager.request(completeUrl, method: convertType(type), parameters: params, encoding: JSONEncoding.default, headers: header)
            .responseString {response in
               // print(response.result,response.response as Any,response)
                let url = response.description
               // print(url)
                UserDefaults.standard.set(url, forKey: "facebookLink")
                UserDefaults.standard.synchronize()
               // print(header)
            }
            .responseJSON { response in
                switch response.result {
                case .success:
                    completionHandler(self.verifyResponse(response, myView: currentView))
                case .failure(let error):
                    completionHandler(nil)
                    print("Error in API: \(error.localizedDescription)")
                }
        }
	}
    
	// MARK: Current UIView
	 class func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
		if let nav = base as? UINavigationController {
			return topViewController(nav.visibleViewController)
		}
		if let tab = base as? UITabBarController {
			if let selected = tab.selectedViewController {
				return topViewController(selected)
			}
		}
		if let presented = base?.presentedViewController {
			return topViewController(presented)
		}
		return base
	}
	// MARK: Alamofire Type
	fileprivate class func convertType(_ type: Method) -> Alamofire.HTTPMethod {
		if(Method.POST == type) {
			return Alamofire.HTTPMethod.post
		}
		if(Method.DELETE == type) {
			return Alamofire.HTTPMethod.delete
		}
		if(Method.PUT == type) {
			return Alamofire.HTTPMethod.put
		}
		return Alamofire.HTTPMethod.get
	}
	
	// MARK: JSON
    fileprivate class func verifyResponse(_ response:  DataResponse<Any>, myView: UIView?) -> JSON?{
		if let data = response.result.value {
			let json = JSON(data)
            
			if let statusCode = response.response?.statusCode {
            
                if statusCode == 400{
//                    myView?.makeToast("Error!. Invalid Response", duration: 2.0, position: .center)
//                    myView?.hideToastActivity()
                }
                else if statusCode == 404 {
//                    myView?.makeToast("Error!. Invalid Response", duration: 2.0, position: .center)
//                    myView?.hideToastActivity()
                }
                else if statusCode == 500 {
//                    myView?.makeToast("Check your internet connection", duration: 2.0, position: .center)
//                    myView?.hideToastActivity()
                }
                else if statusCode == 200 {
                    print("200")
                   // myView?.hideToastActivity()
                }
                else if statusCode == 201 {
                    print("201")
                    // myView?.hideToastActivity()
                }
                else {
                    print("Error")
//                    myView?.makeToast("Error!. Invalid Response", duration: 2.0, position: .center)
//                    myView?.hideToastActivity()
                    return nil
                }
            
                return json
                
            }
            else {
                return nil
            }
            
		}
		return nil
	}

	class func downloadFile(_ url: String, name : String, completionHandler: @escaping (_ response: URL) -> ()){
			
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            documentsURL.appendPathComponent(name)
            return (documentsURL, [.removePreviousFile])
        }
			
			
        Alamofire.download(url, to: destination).responseData { response in
            completionHandler(response.destinationURL!)
        
        }
	}
	
	
	
    fileprivate class func uploadFiles(_ url: String, params: [String:Any]?, files: [String: OMFile], currentView: UIView?,header:[String:String],completionHandler: @escaping (_ response: JSON?) -> ()) {
		var completeUrl = url
		if url.range(of: "http:") != nil {
			completeUrl = url
		}
        
        let authToken = UserDefaults.standard.string(forKey: "AccessToken")
		//let data = filesUrlRequestWithComponents(parameters: params, files: files)
        var headers: HTTPHeaders = ["Content-Type": "multipart/form-data;boundary="+boundaryConstant]
        
        headers = ["Content-Type": "application/json","Authorization" : "bearer \(authToken!)"]
       
		let defaults = UserDefaults.standard
		if let authToken = defaults.string(forKey: "authToken") {
			headers["KN-Auth-Token"] = authToken
		}
		
        let uURL = URL(string: completeUrl)
        do {
         
            let urlRequest = try URLRequest(url: uURL!, method: .post, headers: headers)
           Alamofire.upload(multipartFormData: { (multipartFormData) in
            for (key, value) in params ??  [:]  {
                   multipartFormData.append((value as! String).data(using: String.Encoding.utf8)!, withName: key)
               }
            
            for (key, value) in files {
                guard let imgData = value.data else { return }
                multipartFormData.append(imgData, withName: key, fileName: value.fileName, mimeType: "image/jpeg")
            }


            }, with: urlRequest) { (result) in
                switch result {
                case.success(let request, let streamingFromDisk, let streamFileURL):
                    request.responseJSON { (responsejson) in
                        completionHandler(self.verifyResponse(responsejson, myView: currentView))
                    }
                    break;
                case.failure(let error):
                    print(error);
                    break;
                }
           }
        }
        catch let error {
            print(error)
        }
        return
//		Alamofire.upload(data, to: completeUrl, headers: headers)
//			.responseJSON { response in
//				print(response)
//				switch response.result {
//				case .success:
//					completionHandler(self.verifyResponse(response, myView: currentView))
//				case .failure(let error):
//					completionHandler(nil)
//					print(error.localizedDescription)
//				}
//		}
	}
	
	
    fileprivate class func filesUrlRequestWithComponents(parameters:[String: Any]?, files: [String: OMFile]) -> Data {
		let uploadData = NSMutableData()
		
        let boundary = "Boundary-\(boundaryConstant)"
        var body = ""
        
        if let params = parameters {

            for (key, value) in params {
                let paramName = key
                body += "--\(boundary)\r\n"
                body += "Content-Disposition:form-data; name=\"\(paramName)\""
                let paramValue = value as! String
                body += "\r\n\r\n\(paramValue)\r\n"
              }
        }
        
        for (key, value) in files {
            if let data = value.data{
                
                let paramName = key
                body += "--\(boundary)\r\n"
                body += "Content-Disposition:form-data; name=\"\(paramName)\""

                let fileData = data
                let fileContent = fileData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
                let base64url = URL(string: String(format:"data:application/octet-stream;base64,%@", fileContent))

                body += "; filename=\"\(value.fileName)\"\r\n" + "Content-Type: \"content-type header\"\r\n\r\n\(fileContent)\r\n"
            }
        }
        
        body += "--\(boundary)--\r\n";

        return body.data(using: String.Encoding.utf8)!
//        let paramSrc = param["src"] as! String
//        let fileData = try NSData(contentsOfFile:paramSrc, options:[]) as Data
//        let fileContent = String(data: fileData, encoding: .utf8)!
//        body += "; filename=\"\(paramSrc)\"\r\n"
//          + "Content-Type: \"content-type header\"\r\n\r\n\(fileContent)\r\n"

//
//		for (key, value) in files {
//			if let data = value.data{
//				uploadData.append("\r\n--\(boundaryConstant)\r\n".data(using: String.Encoding.utf8)!)
//				uploadData.append(String("Content-Disposition: form-data; name=\"" + key + "\"; filename=\""+value.fileName+"\"\r\n").data(using: String.Encoding.utf8)!)
//				if let contentType = value.contentType{
//					uploadData.append(("Content-Type: " + contentType + "\r\n\r\n").data(using: String.Encoding.utf8)!)
//				}
//				uploadData.append(data)
//			}
//		}
//		if let params = parameters {
//			for (key, value) in params {
//				uploadData.append("\r\n--\(boundaryConstant)\r\n".data(using: String.Encoding.utf8)!)
//				uploadData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
//			}
//		}
//		uploadData.append("\r\n--\(boundaryConstant)--\r\n".data(using: String.Encoding.utf8)!)
//		return uploadData as Data
	}
}



