
Pod::Spec.new do |s|

  s.name         = "SwiftMongoDB"
  s.version      = "0.0.2"
  s.summary      = "SwiftMongoDB is a Swifter way to interface with MongoDB"
  s.homepage     = "https://github.com/danappelxx/SwiftMongoDB"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Dan Appel" => "dan.appel00@gmail.com" }
  s.osx.deployment_target = '10.10'
  s.requires_arc = true
  s.source       = { :git => "https://github.com/danappelxx/SwiftMongoDB.git", :tag => "#{s.version}" }
  s.source_files  = 'swiftMongoDB', 'swiftMongoDB/*.{h,swift}'
  s.dependency 'mongo-c-driver', '~> 0.8.1'

end
