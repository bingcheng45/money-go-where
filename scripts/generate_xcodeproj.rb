#!/usr/bin/env ruby

require "xcodeproj"
require "fileutils"
require "pathname"

ROOT = File.expand_path("..", __dir__)
PROJECT_PATH = File.join(ROOT, "MoneyGoWhere.xcodeproj")
APP_SOURCES_PATH = File.join(ROOT, "MoneyGoWhere")
TEST_SOURCES_PATH = File.join(ROOT, "MoneyGoWhereTests")

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes["LastUpgradeCheck"] = "2640"
project.root_object.attributes["TargetAttributes"] = {}

app_target = project.new_target(:application, "MoneyGoWhere", :ios, "17.0")
test_target = project.new_target(:unit_test_bundle, "MoneyGoWhereTests", :ios, "17.0")

[
    app_target,
    test_target
].each do |target|
    target.build_configurations.each do |config|
        config.build_settings["SWIFT_VERSION"] = "6.0"
        config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
        config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
        config.build_settings["DEVELOPMENT_TEAM"] = ""
        config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
        config.build_settings["CLANG_ENABLE_MODULES"] = "YES"
        config.build_settings["SWIFT_EMIT_LOC_STRINGS"] = "NO"
    end
end

app_target.build_configurations.each do |config|
    config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.moneygowhere.app"
    config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
    config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
    config.build_settings["ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"] = "AccentColor"
    config.build_settings["TARGETED_DEVICE_FAMILY"] = "1"
    config.build_settings["INFOPLIST_KEY_UIApplicationSceneManifest_Generation"] = "YES"
    config.build_settings["INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents"] = "YES"
    config.build_settings["INFOPLIST_KEY_UILaunchScreen_Generation"] = "YES"
    config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
    config.build_settings["MARKETING_VERSION"] = "1.0"
    config.build_settings["ENABLE_PREVIEWS"] = "YES"
end

test_target.build_configurations.each do |config|
    config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.moneygowhere.app.tests"
    config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
    config.build_settings["TARGETED_DEVICE_FAMILY"] = "1"
    config.build_settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/MoneyGoWhere.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/MoneyGoWhere"
    config.build_settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
end

project.main_group.set_source_tree("SOURCE_ROOT")
app_group = project.main_group.new_group("MoneyGoWhere")
test_group = project.main_group.new_group("MoneyGoWhereTests")

def add_files(group, root_path, target)
  Dir.glob(File.join(root_path, "**", "*")).sort.each do |path|
    next if File.directory?(path)

    relative_path = Pathname(path).relative_path_from(Pathname(ROOT)).to_s
    file_ref = group.find_file_by_path(relative_path) || group.new_file(relative_path)
    target.add_file_references([file_ref])
  end
end

add_files(app_group, APP_SOURCES_PATH, app_target)
add_files(test_group, TEST_SOURCES_PATH, test_target)

test_target.add_dependency(app_target)

# --- RevenueCat SPM dependency ---
revenuecat_package = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
revenuecat_package.repositoryURL = "https://github.com/RevenueCat/purchases-ios"
revenuecat_package.requirement = {
  "kind" => "upToNextMajorVersion",
  "minimumVersion" => "5.0.0"
}
project.root_object.package_references << revenuecat_package

revenuecat_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
revenuecat_dep.package = revenuecat_package
revenuecat_dep.product_name = "RevenueCat"

app_target.package_product_dependencies << revenuecat_dep
# --- end RevenueCat ---

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app_target, test_target, launch_target: app_target)
scheme.save_as(PROJECT_PATH, "MoneyGoWhere", true)

project.save
