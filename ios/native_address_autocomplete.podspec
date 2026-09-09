#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint native_address_autocomplete.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'native_address_autocomplete'
  s.version          = '0.0.1'
  s.summary          = 'Native address autocomplete widgets for Flutter.'
  s.description      = <<-DESC
A customizable Flutter address autocomplete plugin powered by Apple MapKit on iOS and Android Geocoder on Android. It includes TextField and FormField widgets, address resolution, and no required API keys.
                       DESC
  s.homepage         = 'https://github.com/samchancanada1/native_address_autocomplete'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sam Chan' => 'samchancanada1@users.noreply.github.com' }
  s.source           = { :path => '.' }
  s.source_files = 'native_address_autocomplete/Sources/native_address_autocomplete/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'native_address_autocomplete_privacy' => ['native_address_autocomplete/Sources/native_address_autocomplete/PrivacyInfo.xcprivacy']}
end
