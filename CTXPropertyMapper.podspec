Pod::Spec.new do |s|
  
  s.name     = 'CTXPropertyMapper'
  s.version  = '1.0.0'
  s.summary  = 'Simple and highly extensible two ways property mapper'
  s.homepage = "https://github.com/ef-ctx/CTXPropertyMapper"
  
  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.authors      = {
    "Mário Araújo" => "mario.araujo@ef.com"
  }

  s.platform     = :ios
  s.ios.deployment_target = '6.0'
  s.requires_arc = true
  
  s.source   = { :git => 'git@github.com:ef-ctx/CTXPropertyMapper.git', :tag => spec.version.to_s }
  s.source_files = 'CTXPropertyMapper/*.{h,m}'
  
end
