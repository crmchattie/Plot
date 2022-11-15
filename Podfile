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
  pod 'Eureka', '~> 5.3.6'
  pod 'SplitRow'
  pod 'ViewRow'
  pod 'FSCalendar', :modular_headers => true
  pod 'CodableFirebase'
  pod 'FloatingPanel', '~> 1.6.5'
  pod 'Charts'

  pod 'GoogleSignIn'
  pod 'GoogleAPIClientForREST/Calendar'
  pod 'GoogleAPIClientForREST/Tasks'
end

# target 'ShareExtension' do
  # pod 'Firebase/Core', '~> 8.15.0'
  # pod 'Firebase/Database', '~> 8.15.0'
  # pod 'Firebase/Auth', '~> 8.15.0'
  # pod 'Firebase/Storage', '~> 8.15.0'
  # pod 'Firebase/Messaging', '~> 8.15.0'
# end

# Inherits version number from the parent target, therefore silencing a warning for each pod.
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            # Removes the default deployment target
            config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
            if target.name == "SwiftAlgorithms"
                config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
            end
        end
    end
end
