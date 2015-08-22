
Pod::Spec.new do |s|

  s.name         = "SwiftMongoDB"
  s.version      = "0.0.1"
  s.summary      = "SwiftMongoDB is a Swifter way to interface with MongoDB"
  s.homepage     = "https://github.com/danappelxx/SwiftMongoDB"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Dan Appel" => "dan.appel00@gmail.com" }
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.requires_arc = true
  s.source       = { :git => "https://github.com/danappelxx/SwiftMongoDB.git", :tag => "#{s.version}" }
  s.source_files  = 'swiftMongoDB', 'swiftMongoDB/*.{h,swift}'
  # s.public_header_files = %w(HBHandlebars.h runtime/HBTemplate.h runtime/HBExecutionContext.h runtime/HBExecutionContextDelegate.h runtime/HBEscapingFunctions.h context/HBDataContext.h context/HBHandlebarsKVCValidation.h helpers/HBHelper.h helpers/HBHelperRegistry.h helpers/HBHelperCallingInfo.h helpers/HBHelperUtils.h helpers/HBEscapedString.h partials/HBPartial.h partials/HBPartialRegistry.h errorHandling/HBErrorHandling.hd).map{|f| "handlebars-objc/#{f}"}
  # s.header_dir = "HBHandlebars"
  s.dependency 'mongo-c-driver', '~> 0.8.1'

end

#pod 'mongo-c-driver', '~> 0.8.1'
