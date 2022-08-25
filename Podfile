platform :ios, '13.0'
inhibit_all_warnings!

target 'Plot' do
  pod 'Firebase/Core', '~> 8.15.0'
  pod 'Firebase/Database', '~> 8.15.0'
  pod 'Firebase/Auth', '~> 8.15.0'
  pod 'Firebase/Storage', '~> 8.15.0'
  pod 'Firebase/Analytics', '~> 8.15.0'
  pod 'Firebase/Messaging', '~> 8.15.0'

  pod 'SDWebImage', :modular_headers => true
  pod 'PhoneNumberKit'
  pod 'FLAnimatedImage', :modular_headers => true
  pod 'FTPopOverMenu_Swift', '~> 0.2.0'
  pod 'CropViewController'
  pod 'Eureka' 
  pod 'SplitRow'
  pod 'ViewRow'
  pod 'FSCalendar', :modular_headers => true
  pod 'CodableFirebase'
  pod 'FloatingPanel', '~> 1.6.5'
  pod 'Charts', '~> 3.6.0'

  pod 'GoogleSignIn', '~> 5.0.2'
  pod 'GoogleAPIClientForREST/Calendar'
  pod 'GoogleAPIClientForREST/Tasks'
end

target 'ShareExtension' do
  pod 'Firebase/Core', '~> 8.15.0'
  pod 'Firebase/Database', '~> 8.15.0'
  pod 'Firebase/Auth', '~> 8.15.0'
  pod 'Firebase/Storage', '~> 8.15.0'
  pod 'Firebase/Messaging', '~> 8.15.0'
end

# Inherits version number from the parent target, therefore silencing a warning for each pod.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Removes the default deployment target
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
