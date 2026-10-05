#!/usr/bin/env ruby
# Project generation is optional: the generated project is committed for fresh clones.
require 'xcodeproj'

root = File.expand_path(__dir__)
project = Xcodeproj::Project.new(File.join(root, 'AQD.xcodeproj'))
app = project.new_target(:application, 'AQD', :ios, '18.0')
unit = project.new_target(:unit_test_bundle, 'AQDTests', :ios, '18.0')
ui = project.new_target(:ui_test_bundle, 'AQDUITests', :ios, '18.0')
unit.add_dependency(app)
ui.add_dependency(app)

project.build_configurations.each do |config|
  config.build_settings.merge!('SWIFT_VERSION' => '6.0', 'CLANG_ENABLE_MODULES' => 'YES')
end
[app, unit, ui].each do |target|
  group = project.main_group.new_group(target.name, target.name)
  Dir.glob(File.join(root, target.name, '**', '*.swift')).sort.each do |path|
    target.add_file_references([group.new_file(path.delete_prefix(root + '/' + target.name + '/'))])
  end
  target.build_configurations.each do |config|
    config.build_settings.merge!(
      'PRODUCT_BUNDLE_IDENTIFIER' => "com.aqd.ios#{target == app ? '' : '.' + target.name}",
      'SWIFT_VERSION' => '6.0', 'SWIFT_STRICT_CONCURRENCY' => 'complete',
      'TARGETED_DEVICE_FAMILY' => '1', 'GENERATE_INFOPLIST_FILE' => 'YES',
      'CODE_SIGN_STYLE' => 'Automatic', 'MARKETING_VERSION' => '0.1.0', 'CURRENT_PROJECT_VERSION' => '1'
    )
    if target == unit
      config.build_settings.merge!('TEST_HOST' => '$(BUILT_PRODUCTS_DIR)/AQD.app/AQD', 'BUNDLE_LOADER' => '$(TEST_HOST)')
    elsif target == ui
      config.build_settings['TEST_TARGET_NAME'] = 'AQD'
    else
      config.build_settings.merge!(
        'INFOPLIST_FILE' => 'AQD/Resources/Info.plist',
        'CODE_SIGN_ENTITLEMENTS' => 'AQD/Resources/AQD.entitlements',
        'INFOPLIST_KEY_UILaunchStoryboardName' => 'LaunchScreen',
        'INFOPLIST_KEY_UIApplicationSceneManifest_Generation' => 'YES',
        'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon'
      )
      local = project.main_group.new_file('Configuration/App.xcconfig')
      config.base_configuration_reference = local
    end
  end
end
resources = project.main_group.new_group('Resources', 'AQD/Resources')
app.resources_build_phase.add_file_reference(resources.new_file('Assets.xcassets'))
app.resources_build_phase.add_file_reference(resources.new_file('PrivacyInfo.xcprivacy'))
app.resources_build_phase.add_file_reference(resources.new_file('LaunchScreen.storyboard'))

sdk = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
sdk.repositoryURL = 'https://github.com/supabase/supabase-swift.git'
sdk.requirement = { 'kind' => 'exactVersion', 'version' => '2.55.3' }
project.root_object.package_references << sdk
dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
dependency.package = sdk
dependency.product_name = 'Supabase'
app.package_product_dependencies << dependency
framework = project.new(Xcodeproj::Project::Object::PBXBuildFile)
framework.product_ref = dependency
app.frameworks_build_phase.files << framework
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
scheme.add_test_target(unit)
scheme.add_test_target(ui)
scheme.save_as(project.path, 'AQD', true)
