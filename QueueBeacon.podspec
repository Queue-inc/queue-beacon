# coding: utf-8

Pod::Spec.new do |s|
  s.name         = "QueueBeacon"
  s.version      = "1.0.0"
  s.summary      = "Beacon Plugin for Weex created by Queue.Inc"

  s.description  = <<-DESC
                   Weexplugin Source Description
                   DESC

  s.homepage     = "https://github.com"
  s.license = {
    :type => 'Copyright',
    :text => <<-LICENSE
            copyright
    LICENSE
  }
  s.authors      = {
                     "subdiox" => "subdiox@gmail.com"
                   }
  s.platform     = :ios
  s.ios.deployment_target = "8.0"

  s.source       = { :git => 'https://github.com/Queue-inc/queue-beacon', :tag => '1.0.0' }
  s.source_files  = "ios/Sources/*.{h,m,mm}"
  
  s.requires_arc = true
  s.dependency "WeexPluginLoader"
  s.dependency "WeexSDK"
end
