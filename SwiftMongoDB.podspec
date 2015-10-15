Pod::Spec.new do |s|

  s.name         = "SwiftMongoDB"
  s.version      = "0.2.0"
  s.summary      = "SwiftMongoDB is a Swifter way to interface with MongoDB"
  s.description  = <<-DESC
                   SwiftMongoDB provides you with a very clean api through which you can interface with MongoDB.

                   Currently supports most basic operations (more features coming soon!).
                   DESC
  s.homepage     = "https://github.com/danappelxx/SwiftMongoDB"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Dan Appel" => "dan.appel00@gmail.com" }
  s.source       = { :git => "https://github.com/danappelxx/SwiftMongoDB.git", :tag => "#{s.version}" }

  s.osx.deployment_target = '10.10'
  s.ios.deployment_target = '8.0'

  s.source_files  = 'swiftMongoDB/dependencies/*.{h,dylib}', 'swiftMongoDB/dependencies/{mongoc,bson,private}/*.{h}', 'swiftMongoDB/*.{h,swift}'
  s.library = 'mongoc', 'bson'

end
