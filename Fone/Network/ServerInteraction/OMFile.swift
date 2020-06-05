//
//  OMFile.swift
//  OneMinute
//
//  Created by Shan Shafiq on 4/1/17.
//  Copyright © 2017 azantech. All rights reserved.
//

import Foundation
import UIKit
class OMFile: NSObject {
	
	var data: Data?
	var fileName: String
	var contentType: String?
	
	required init(data: Data, fileName: String, contentType: String?) {
		self.data = data
		self.fileName = fileName
		self.contentType = contentType
	}
	
    required init(image: UIImage, of imageSize: CGSize) {
		let imgResized = Utility.sharedInstance.resizeImageToSize(image, tSize: imageSize)
        self.data = imgResized.jpegData(compressionQuality: 1.0)
        self.fileName = UUID().uuidString + ".jpeg"
		self.contentType = "image/jpeg"
	}
	
	required init(path: URL) {
		self.data = try? Data(contentsOf: path)
		self.fileName = "file." + path.pathExtension
		self.contentType = "application/octet-stream"
	}
	
	required init(path: URL, name: String) {
		self.data = try? Data(contentsOf: path)
		self.fileName = name + "." + path.pathExtension
		self.contentType = "application/octet-stream"
	}
	
}
