Pod::Spec.new do |s|

  s.name         = 'JSONStore'
  s.version      = '1.0.0'
  s.summary      = 'JSONStore for iOS'

  s.description  = <<-DESC
    JSONStore is a lightweight, document-oriented storage system that enables persistent storage of JSON documents for iOS applications.
    DESC

  s.homepage     = 'https://github.com/ibm-bluemix-mobile-services/jsonstore-ios'

  s.license      = { :type => 'Apache License, Version 2.0', :file => 'LICENSE'}

  s.author             = { 'IBM Bluemix Mobile Services' => 'mobilesdk@us.ibm.com' }
  
  s.source       = { :git => 'https://github.com/ibm-bluemix-mobile-services/jsonstore-ios.git', :tag => '1.0.0'}



  s.source_files  = 'JSONStore', 'JSONStore/**/*.{h,m}'
  s.exclude_files = 'JSONStore/Exclude'

  s.requires_arc = true

  s.libraries = 'sqlite3'

  s.module_map = 'module.modulemap'

end
