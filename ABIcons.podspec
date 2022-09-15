Pod::Spec.new do |s|
  s.name                  = 'ABIcons'
  s.version               = '0.2.1'
  s.summary               = 'App to add application version to application icon'
  s.description           = <<-DESC
  Use this tool if you want to see version number on your icon. This could be useful for debug and test builds.
                            DESC
  s.homepage              = 'https://github.com/CleverPumpkin/abicons-ios'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { 'CleverPumpkin Ltd' => 'company@cleverpumpkin.ru' }
  s.source                = { :git => 'https://github.com/CleverPumpkin/abicons-ios.git', :tag => s.version.to_s }
  s.platform              = :ios
  s.swift_version         = '5.0'
  s.ios.deployment_target = 10.3
  s.preserve_path         = 'Binary/ABIcons'
  s.user_target_xcconfig  = { 'ABICONS_PATH' => "${PODS_ROOT}/#{s.name}/Binary/ABIcons" }

end
