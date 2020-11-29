# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Fone' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Fone
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'Firebase/Crashlytics'
  pod 'MASegmentedControl'

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
  pod 'Branch'
  pod 'SendBirdSDK'
  pod 'AlamofireImage', '~> 3.4'
  pod 'RSKImageCropper'
  pod 'NYTPhotoViewer', '~> 1.1.0'
  pod 'FLAnimatedImage', '~> 1.0'
  pod 'Google-Mobile-Ads-SDK'
  pod 'OneSignal'


  target 'OneSignalNotificationServiceExtension' do
    pod 'OneSignal'
  end

  target 'FoneTests' do
    inherit! :search_paths
    # Pods for testing
  end

#  target 'FoneUITests' do
#    inherit! :search_paths
#    # Pods for testing
#  end
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
       end
    end
  end
 
end

