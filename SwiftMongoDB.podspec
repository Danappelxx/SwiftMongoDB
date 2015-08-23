
Pod::Spec.new do |s|

  s.name         = "SwiftMongoDB"
  s.version      = "0.0.4"
  s.summary      = "SwiftMongoDB is a Swifter way to interface with MongoDB"
  s.description  = <<-DESC
                   SwiftMongoDB provides you with a very clean api through which you can interface with MongoDB.

                   Includes most basic MongoDB features, more coming (hopefully) very soon.
                   DESC
  s.homepage     = "https://github.com/danappelxx/SwiftMongoDB"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Dan Appel" => "dan.appel00@gmail.com" }
  s.source       = { :git => "https://github.com/danappelxx/SwiftMongoDB.git", :tag => "#{s.version}" }

  s.platform     = :osx, '10.10'
  # s.osx.deployment_target = '10.10'
  s.requires_arc = true

  s.source_files  = 'swiftMongoDB', 'swiftMongoDB/*.{h,swift}'

  s.dependency 'mongo-c-driver', '~> 0.8.1'

end
