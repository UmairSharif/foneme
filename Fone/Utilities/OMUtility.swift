//
//  OMUtility.swift
//  RestaurantFinder
//
//  Created by Hamza on 10/16/18.
//  Copyright © 2018 mindslab. All rights reserved.
//

import Foundation
import SDWebImage
import CoreLocation
class Utility {
    class var sharedInstance: Utility {
        struct Static {
            static let instance: Utility = Utility()
        }
        return Static.instance
    }
    
    func getScreenWidth() -> CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    
    func getScreenHeight() -> CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    func getImageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func resizeImage(_ img: UIImage) -> (UIImage) {
        let targetSize = CGSize(width: 1024, height: 1024)
        let newimage = resizeImageToSize(img, tSize: targetSize)
        return newimage
    }
    
    func changeImageColor(_ originalImage: UIImage) -> UIImage? {
        
        let templateImage = originalImage.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        let myImageView = UIImageView(image: templateImage)
        myImageView.tintColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
        
        return myImageView.image
    }
    
    func resizeImageToSize(_ img: UIImage, tSize: CGSize) -> (UIImage) {
        let targetSize = tSize
        let img = img
        var newImage: UIImage!
        let imageSize = img.size
        
        let width: CGFloat = imageSize.width
        let height: CGFloat = imageSize.height
        let targetWidth: CGFloat = targetSize.width;
        let targetHeight: CGFloat = targetSize.height
        var scaleFactor: CGFloat = 0.0;
        var scaledWidth: CGFloat = targetWidth;
        var scaledHeight: CGFloat = targetHeight;
        var thumbnailPoint: CGPoint = CGPoint(x: 0.0, y: 0.0)
        if (imageSize != targetSize) {
            let widthFactor: CGFloat = targetWidth / width;
            let heightFactor: CGFloat = targetHeight / height
            
            if (widthFactor > heightFactor) {
                scaleFactor = widthFactor;
            } else {
                scaleFactor = heightFactor;
            }
            scaledWidth = width * scaleFactor
            scaledHeight = height * scaleFactor
            if (widthFactor > heightFactor) {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
            } else {
                if (widthFactor < heightFactor) {
                    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
                }
            }
        }
        
        UIGraphicsBeginImageContext(targetSize);
        var thumbnailRect = CGRect.zero
        thumbnailRect.origin = thumbnailPoint;
        thumbnailRect.size.width = scaledWidth;
        thumbnailRect.size.height = scaledHeight;
        img.draw(in: thumbnailRect)
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        if(newImage == nil) {
            
        }
        
        UIGraphicsEndImageContext();
        return newImage
    }
    
    // MARK: Validation
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        return (password.count > 5) ? true : false
    }
    
    func isEmpty(_ field: String) -> Bool {
        return (field.count > 0) ? false : true
    }
    
    func isValidFullName(_ fullName: String) -> Bool {
        let fullNameArr = fullName.split { $0 == " " }.map { String($0) }
        return fullNameArr.count > 1 ? true : false
    }
    
    func dateToDay(_ date: Date) -> String {
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "h:mm a"
        return dayTimePeriodFormatter.string(from: date)
    }
    
    func timeAgoSinceDate(_ date: Date, numericDates: Bool) -> String? {
        let calendar = Calendar.current
        let now = Date()
        let earliest = (now as NSDate).earlierDate(date)
        let latest = (earliest == now) ? date : now
        let components: DateComponents = (calendar as NSCalendar).components([.day, .month, .year, .second, .minute, .hour, .weekOfYear], from: earliest, to: latest, options: [])
        if (components.year! >= 2) {
            return "\(components.year!) years ago"
        } else if (components.year! >= 1) {
            if (numericDates) {
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if (components.month! >= 2) {
            return "\(components.month!) months ago"
        } else if (components.month! >= 1) {
            if (numericDates) {
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear! >= 2) {
            return "\(components.weekOfYear!) weeks ago"
        } else if (components.weekOfYear! >= 1) {
            if (numericDates) {
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if (components.day! >= 2) {
            return "\(components.day!) days ago"
        } else if (components.day! >= 1) {
            if (numericDates) {
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if (components.hour! >= 2) {
            return "\(components.hour!) hours ago"
        } else if (components.hour! >= 1) {
            if (numericDates) {
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if (components.minute! >= 2) {
            return "\(components.minute!) minutes ago"
        } else if (components.minute! >= 1) {
            if (numericDates) {
                return "1 minute ago"
            } else {
                return "1 minute ago"
            }
        } else if (components.second! >= 3) {
            return "\(components.second!) seconds ago"
        } else {
            return "Just now"
        }
    }
    
    func dateToDayFunction(_ date: Date) -> String {
        let dateCurrent = Date()
        let calendar = Calendar.current
        let components1 = (calendar as NSCalendar).components([.day, .month, .year], from: date)
        let components2 = (calendar as NSCalendar).components([.day, .month, .year], from: dateCurrent)
        let date1 = calendar.date(from: components1)
        let date2 = calendar.date(from: components2)
        if (date1!.compare(date2!) == ComparisonResult.orderedDescending) {
            let components = (calendar as NSCalendar).components([.day], from: dateCurrent, to: date, options: [])
            if components.day! >= 1
            {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yyyy"
                return dateFormatter.string(from: date)
                
            } else {
                return "Tomorrow"
            }
        } else if (date1!.compare(date2!) == ComparisonResult.orderedAscending) {
            let components = (calendar as NSCalendar).components([.day], from: date, to: dateCurrent, options: [])
            if components.day! > 1
            {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yyyy"
                return dateFormatter.string(from: date)
            } else {
                return "Yesterday"
            }
        } else {
            return "Today"
        }
    }
    
    func getTimeFromDateString (_ dateString: String) -> String {
        let dtf = DateFormatter()
        dtf.timeZone = TimeZone.current
        dtf.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"   //  2018-08-30T17:02:41.459Z
        let date = dtf.date(from: dateString)
        let dfTime = DateFormatter()
        dfTime.dateFormat = "hh:mm a"
        dfTime.string(from: date!)
        dfTime.timeZone = TimeZone.current
        return dfTime.string(from: date!)
    }
    
    func getTimeFromDateObject (_ date: Date) -> String {
        let dtf = DateFormatter()
        dtf.timeZone = TimeZone.current
        dtf.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"   //  2018-08-30T17:02:41.459Z
        let dateString = dtf.string(from: date)
        let dateConvrtd = dtf.date(from: dateString)
        let dfTime = DateFormatter()
        dfTime.dateFormat = "hh:mm a"
        dfTime.string(from: dateConvrtd!)
        dfTime.timeZone = TimeZone.current
        return dfTime.string(from: dateConvrtd!)
    }
    
    func getDateObjectFromDateString(_ dateString: String) -> Date? {
        
        let dtf = DateFormatter()
        dtf.timeZone = TimeZone.current
        dtf.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"   //  2018-08-30T17:02:41.459Z
        let date = dtf.date(from: dateString)
        if date != nil {
            return date!
        }
        return nil
    }
    
    func getDateFromDateString (_ dateString: String) -> String {
        let dtf = DateFormatter()
        dtf.timeZone = TimeZone.current
        dtf.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"   //  2018-08-30T17:02:41.459Z
        let date = dtf.date(from: dateString)
        let dfDate = DateFormatter()
        dfDate.dateFormat = "yyyy-MM-dd"
        dfDate.string(from: date!)
        dfDate.timeZone = TimeZone.current
        return dfDate.string(from: date!)
    }
    
    func getDateFromDateObject (_ date: Date) -> String {
        let dtf = DateFormatter()
        dtf.timeZone = TimeZone.current
        dtf.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"   //  2018-08-30T17:02:41.459Z
        let dateString = dtf.string(from: date)
        let dateConvrtd = dtf.date(from: dateString)
        let dfDate = DateFormatter()
        dfDate.dateFormat = "yyyy-MM-dd"
        dfDate.string(from: dateConvrtd!)
        dfDate.timeZone = TimeZone.current
        return dfDate.string(from: dateConvrtd!)
    }
    
    
    func getDateFromString (_ dateString: String?, _ format: String) -> Date? {
        if let dateString = dateString {
            let dtf = DateFormatter()
            dtf.timeZone = TimeZone.current
            dtf.dateFormat = format
            return dtf.date(from: dateString)
        }
        return nil
    }
    func diffranceBetweenDays(formatedStartDate : Date) -> Int {
        
        let currentDate = Date()
        let components = Set<Calendar.Component>([.second, .minute, .hour, .day, .month, .year])
        let differenceOfDate = Calendar.current.dateComponents(components, from: currentDate, to: formatedStartDate )
        return differenceOfDate.day ?? 0;

    }
    
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for _ in 0..<len {
            let length = UInt32(letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        
        return randomString
    }
    
    
}
