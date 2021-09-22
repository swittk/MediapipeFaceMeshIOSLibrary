Pod::Spec.new do |s|  
    s.name              = 'FaceMeshIOSLibFramework'
    s.version           = '0.5.0'
    s.summary           = 'MediaPipe FaceMesh Library compiled for iOS'
    s.homepage          = 'https://swittssoftware.com/'

    s.author            = { 'swittk' => 'you@yourcompany.com' }
    s.license           = { :type => 'MIT', :file => 'LICENSE' }

    s.platform          = :ios
    s.source            = { :http => 'https://github.com/swittk/MediapipeFaceMeshIOSLibrary/releases/download/0.5.0/FaceMeshIOSLibFramework.xcframework.zip' }
#    s.source_files      = "add your header files which would be public"
    s.ios.deployment_target = '11.0'
    s.ios.vendored_frameworks = 'FaceMeshIOSLibFramework.xcframework'
end