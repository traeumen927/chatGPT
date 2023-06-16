# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'chatGPT' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for chatGPT
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxGesture'
  pod 'SnapKit'
  pod 'Alamofire'

  target 'chatGPTTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'chatGPTUITests' do
    # Pods for testing
  end
  
  post_install do |installer|
   installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
     config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
   end
  end

end
