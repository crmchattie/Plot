platform :ios, '13.0'
inhibit_all_warnings!

target 'Plot' do
  pod 'Firebase/Core'
  pod 'Firebase/Database'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'Firebase/Analytics'
  pod 'Firebase/Messaging'

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
  pod 'FloatingPanel'
  pod 'Charts'

  pod 'GoogleSignIn'
  pod 'GoogleAPIClientForREST/Calendar'
end

target 'ShareExtension' do
  pod 'Firebase/Core'
  pod 'Firebase/Database'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'
  pod 'Firebase/Messaging'
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
