Pod::Spec.new do |spec|
  
  spec.name     = 'CTXPropertyMapper'
  spec.version  = '1.1.0'
  spec.summary  = 'Simple and highly extensible two ways property mapper'
  spec.homepage = "https://github.com/ef-ctx/CTXPropertyMapper"
  
  spec.license      = { :type => 'MIT', :file => 'LICENSE' }

  spec.authors      = {
    "Mário Araújo" => "mario.araujo@ef.com"
  }

  spec.platform     = :ios
  spec.ios.deployment_target = '6.0'
  spec.requires_arc = true
  
  spec.source   = { :git => 'https://github.com/ef-ctx/CTXPropertyMapper.git', :tag => spec.version.to_s }
  spec.source_files = 'CTXPropertyMapper/*.{h,m}'
  
end
