Pod::Spec.new do |s|
  s.name                  = 'ABIcons'
  s.version               = '0.1.0'
  s.summary               = 'App to add application version to application icon'
  s.description           = <<-DESC
  Tool if you want to see version number on your icon. This could be useful for debug and test builds.
                            DESC
  s.homepage              = 'https://github.com/CleverPumpkin/abicons-ios'
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.author                = { 'CleverPumpkin Ltd' => 'company@cleverpumpkin.ru' }
  s.source                = { :git => 'https://github.com/CleverPumpkin/abicons-ios.git', :tag => s.version.to_s }
  s.platform              = :ios
  s.swift_version         = '5.0'
  s.ios.deployment_target = 10.3
  # s.source_files          = 'ABIcons/**/*.swift'
  s.prepare_command       = '"Scripts/prepare.sh"'
  s.preserve_paths        = 'ABIcons/Binary/ABIcons', 'Scripts/run.sh'
  s.user_target_xcconfig  = { 'ABICONS_PATH' => "${PODS_ROOT}/#{s.name}/Binary/ABIcons" }
  s.script_phase          = {
    :name => 'ABIcons Step',
    :script => '${PODS_TARGET_SRCROOT}/Scripts/run.sh',
    :execution_position => :before_compile
  }

end
