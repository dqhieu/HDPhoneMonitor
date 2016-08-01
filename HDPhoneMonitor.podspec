Pod::Spec.new do |s|

  # 1
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.name = "HDPhoneMonitor"
  s.summary = "HDPhoneMonitor is a service help monitor your phone"
  s.requires_arc = true

  # 2
  s.version = "0.4.4"

  # 3
  s.license      = 'MIT'

  # 4 - Replace with your name and e-mail address
  s.author = { "Đinh Quang Hiếu" => "dqhieu13@gmail.com" }

  # For example,
  # s.author = { "Joshua Greene" => "jrg.developer@gmail.com" }


  # 5 - Replace this URL with your own Github page's URL (from the address bar)
  s.homepage = "https://github.com/dqhieu/HDPhoneMonitor"

  # For example,
  # s.homepage = "https://github.com/JRG-Developer/RWPickFlavor"


  # 6 - Replace this URL with your own Git URL from "Quick Setup"
  s.source = { :git => "https://github.com/dqhieu/HDPhoneMonitor.git", :tag => "#{s.version}"}

  # For example,
  # s.source = { :git => "https://github.com/JRG-Developer/RWPickFlavor.git", :tag => "#{s.version}"}


  # 7
  s.framework = "UIKit"
  s.dependency 'RealmSwift'
  s.dependency 'GoogleAPIClient/Core', '~> 1.0.2'
  s.dependency 'GTMOAuth2', '~> 1.1.0'
  s.dependency 'SVProgressHUD'


  # 8
  s.source_files = "HDPhoneMonitor/**/*.{swift}"


end
