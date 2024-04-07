#
# Be sure to run `pod lib lint ShipBookSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ShipBookSDK'
  s.version          = '1.2.0'
  s.summary          = 'User & Session-based mobile log platform for iOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  A logging system for iOS. This logging system connects to the ShipBook server. It can also work by its' own without ShipBook Server
                       DESC

  s.homepage         = 'https://shipbook.io'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Elisha Sterngold' => '' }
  s.source           = { :git => 'https://github.com/ShipBook/ShipBookSDK-iOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '11.0'

  s.source_files = 'ShipBookSDK/Classes/**/*'
  
  # s.resource_bundles = {
  #  'ShipBookSDK' => ['ShipBookSDK/Assets/**/*']
  # }
  # s.preserve_path = 'shipbook_build_dsym_upload.sh'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  
  # s.frameworks = 'UIKit', 'MapKit'

  s.swift_version = ['4.2', '5.0', '5.1', '5.2', '5.3', '5.5', '5.6']

end
