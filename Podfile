# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Fone' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Fone
  pod 'Firebase/Analytics'
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'Firebase/Auth'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
  pod 'Firebase/Core'
  pod 'Firebase/RemoteConfig'
  pod 'MASegmentedControl'
  pod 'SVProgressHUD'

  pod 'BraintreeDropIn'
  pod 'Alamofire', '~> 4.7'
  pod 'SwiftyJSON', '~> 4.0'
  pod 'IQKeyboardManagerSwift'
  pod 'SDWebImage', '~> 4.0'
  pod 'NVActivityIndicatorView'
  pod 'CountryPickerView'
 
  pod 'TwilioChatClient', '~> 2.3.0'
  pod 'TwilioVideo'
  pod 'TwilioAccessManager', '~> 1.0.0'
  pod 'ReachabilitySwift'
  pod 'TwilioVoice', '~> 5.1.1'
  pod 'Branch',  '~> 1.39.4'
  pod 'SendBirdSDK'
  pod 'AlamofireImage', '~> 3.4'
  pod 'RSKImageCropper'
  pod 'NYTPhotoViewer', '~> 1.1.0'
  pod 'FLAnimatedImage', '~> 1.0'
  pod 'Google-Mobile-Ads-SDK'
  pod 'OneSignal'
  pod 'GoogleAnalytics'
  pod 'Toast-Swift', '~> 5.0.1'
  pod "TTGTagCollectionView"
  pod 'GoogleSignIn', '~> 6.2.4'
  #pod 'FBSDKLoginKit'
  pod 'FacebookCore'
  pod 'FacebookLogin'
  pod 'Braintree', :inhibit_warnings => true
  pod 'SnapKit'
  pod 'SwiftJWT'
  pod 'Google-Mobile-Ads-SDK'
  
  target 'OneSignalNotificationServiceExtension' do
    pod 'OneSignal'
    pod 'Alamofire', '~> 4.7'
    pod 'SnapKit'
    pod 'SwiftJWT'
  end

  target 'FoneTests' do
    inherit! :search_paths
    # Pods for testing
  end
  
  post_install do |installer|
      # fix xcode 15 DT_TOOLCHAIN_DIR - remove after fix oficially - https://github.com/CocoaPods/CocoaPods/issues/12065
      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
          if config.base_configuration_reference.is_a? Xcodeproj::Project::Object::PBXFileReference
            xcconfig_path = config.base_configuration_reference.real_path
            IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
          end
        end
      end
    end
  end
