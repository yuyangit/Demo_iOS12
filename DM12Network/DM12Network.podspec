#
# Be sure to run `pod lib lint DM12Network.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DM12Network'
  s.version          = '0.1.0'
  s.summary          = 'A short description of DM12Network.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/yuyangit/DM12Network'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yuyangit' => 'yuyangmx2@gmail.com' }
  s.source           = { :git => 'https://github.com/yuyangit/DM12Network.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.subspec 'Message' do |ss|
      ss.source_files = 'DM12Network/Classes/Message/**/**/**'
      ss.public_header_files = 'DM12Network/Classes/Message/**/**/*.h'
  end
  
  s.subspec 'LiveStream' do |ss|
      ss.source_files = 'DM12Network/Classes/LiveStream/**/**/**'
      ss.public_header_files = 'DM12Network/Classes/LiveStream/**/**/*.h'
  end
  
  s.frameworks = 'UIKit', 'Network'
  
end
