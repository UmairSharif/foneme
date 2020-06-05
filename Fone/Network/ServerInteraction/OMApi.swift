//
//  OMApi.swift
//  OneMinute
//
//  Created by Shan Shafiq on 4/1/17.
//  Copyright © 2017 azantech. All rights reserved.
//

import Foundation
//class Api{
//    struct User {
//        static let LOGIN = "auth.php/loginV2"
//        static let REGISTER = "auth.php/login"
//        static let VERIFY = "auth.php/verify"
//        static let PROFILE = "user.php/my_profile/{user_id}"
//        static let UPDATEPROFILE = "user.php/update"
//        static let UPDATEPROFILE_IMAGE = "user.php/update_profile_image"
//        static let ROLESWITCHING = "user.php/switch"
//        static let LOGOUT = "user.php/logout"
//        static let NOTIFY = "driver.php/notify"
//        static let USERLOCATION = "user.php/location/{userId}"
//        static let UPDATETOKEN = "user.php/update_token"
//        static let CHECKING_LOGIN = "user.php/logout_device/{user_id}/{token}"
//        static let REVIEWS_LIST = "rating.php/customer_rating/{user_id}"
//    }
//
//    struct Driver {
//        static let LOAD = "driver.php/nearby/{latitude}/{logitude}"
//        static let FAVOURITE = "favourite.php/id/{user_id}"
//        static let ADDFAVOURITE = "favourite.php/add"
//        static let REMOVEFAVOURITE = "favourite.php/remove"
//        static let UPDATELOCATION = "driver.php/update_location"
//        static let REVIEWS_LIST = "rating.php/driver_rating/{user_id}"
//    }
//
//    struct Shop {
//        static let LOAD = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?sensor=true&key=AIzaSyCsuqdd_x2R4dyyYZGEzcmG6TRHvMTGf4Q&type=restaurant%7Cbakery%7Ccafe%7Chome_goods_store%7Cpharmacy%7Cdepartment_store%7Cshopping_mall%7Celectronics_store%7Cgrocery_or_supermarket&location={latitude},{logitude}&radius=10000&language={lan}"
//        /*https://maps.googleapis.com/maps/api/place/nearbysearch/json?sensor=true&key=AIzaSyCsuqdd_x2R4dyyYZGEzcmG6TRHvMTGf4Q&type=restaurant%7Cbakery%7Ccafe%7Chome_goods_store%7Cpharmacy%7Cdepartment_store%7Cshopping_mall%7Celectronics_store%7Cgrocery_or_supermarket&location={latitude},{logitude}&radius=1000&language={lan}&strictbounds&locale={locale}"*/
//        static let SEARCH = "https://api.foursquare.com/v2/venues/search?query={query}&v={date}&intent=checkin&ll={lat},{lng}&client_id=KPVK2WSD50C4YT2UZXDCOAIJEFFOXMYBWKBZMCIB4DCGJGVO&client_secret=KZEEUIB0TIQWD4ZTLMCTLK0FPSZLBIDH5EYTN1EGF4EZPSSL&limit=50&locale={lang}&radius=40000"
//        static let SEARCHBYTYPE = "https://api.foursquare.com/v2/venues/search?categoryId={categories}&v={date}&intent=checkin&ll={lat},{lng}&client_id=55131D33JOWWDLPEEFOBNSYHKVI0IYNQTRLZFRRYQPPUKBFI&client_secret=P1MYLYWLVN11L4RD0M1CJCCFUKVRJ0GOMSRASQ0TW3I34WWG&limit={itemsCount}&locale={lang}&radius=10000"
//        static let ACTIVE = "shop.php/active/{lat}/{lng}"
//
//        static let CATEGORIES_ARR : Array<Dictionary<String,String>>! =
//            [["All":""], ["Restaurant":"4bf58dd8d48988d1c4941735,52e81612bcbc57f1066b79f8,4bf58dd8d48988d10f941735,52e81612bcbc57f1066b7a05,4bf58dd8d48988d16e941735"],
//             ["Coffee":"4bf58dd8d48988d16d941735,4bf58dd8d48988d1e0931735"],
//             ["Bakery":"4bf58dd8d48988d16a941735"],
//             ["Super Market":"52f2ab2ebcbc57f1066b8b46,4bf58dd8d48988d1fd941735,5744ccdfe4b0c0459246b4dc"],
//             ["Pharmacy":"4bf58dd8d48988d10f951735"],
//             ["Florist":"4bf58dd8d48988d11b951735"],
//             ["Perfume":"52f2ab2ebcbc57f1066b8b23"],
//             ["Books":"4bf58dd8d48988d114951735"],
//             ["Laundry":"4bf58dd8d48988d1fc941735"]]
//    }
//
//    struct Order {
//        static let LOAD = "order.php/{user_id}"
//        static let NEW = "order.php/newV2"
//        static let MARKCOMPLETED = "order.php/mark_completed"
//        static let ALLMESSAGES = "message.php/order/{order_id}"
//        static let POSTMESSAGE = "message.php/post"
//        static let CANCEL = "order.php/cancel"
//        static let ADDBILL = "order.php/add_bill"
//        static let ACCEPT = "order.php/accept"
//        static let RATING = "rating.php/addV2"
//        static let PRICING = "order.php/fare_details"
//        static let TRYAGAIN = "order_retry.php/retry"
//        static let CHECKORDERSTATUS = "order.php/get_status/{order_id}"
//        static let ORDERSTATUS_DRIVER = "order.php/driver_orders_status/{user_id}"
//        static let ORDERSTATUS_CUSTOMER = "order.php/customer_orders_status/{user_id}"
//    }
//
//    struct Offer {
//        static let ACCEPT = "offer.php/accept"
//        static let NEW = "offer.php/submit"
//        static let ALL = "offer.php/all/{order_id}"
//        static let SINGLE = "offer.php/id/{offer_id}"
//    }
//
//    struct Delivery {
//        static let LOAD = "delivery.php/{user_id}"
//        static let CANCEL = "delivery.php/cancel"
//    }
//
//    struct AppRelated {
//        static let VERSION_UPDATED = "version.php/verify/ios/{version}"
//        static let BANKDETAILS = "bank.php/detail"
//        static let SUBMITRECEIPT = "bank.php/payment_receipt"
//        static let ADDCOUPON = "coupon.php/validate"
//        static let ADDPROMO = "promo.php/validate"
//        static let COMPLAINT_BOX = "complain.php/new"
//    }
//
//    struct Verification {
//        static let ALL_IMAGES = "driver.php/verification/status/{user_id}"
//        static let IQDAMA = "driver.php/verification/update_iqama"
//        static let VEHICLE = "driver.php/verification/update_car"
//        static let LICENSE = "driver.php/verification/update_license"
//        static let PROFILE_PIC = "driver.php/verification/update_profile"
//    }
//}
