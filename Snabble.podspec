#
# Be sure to run `pod lib lint Snabble.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name = 'Snabble'
  s.version = '0.18.0'
  s.summary = 'The snabble iOS SDK'

  s.description = <<-DESC
  snabble - the self-scanning and checkout platform
  The SDK provides scanning, checkout and payment services and UI components based on the snabble SaaS platform.
  DESC

  s.homepage = 'https://snabble.io/'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'snabble GmbH' => 'info@snabble.io' }
  s.source = { :git => 'https://github.com/snabble/iOS-SDK.git', :tag => "#{s.version}" }
  s.social_media_url = 'https://twitter.com/snabble_io'

  s.platform = :ios
  s.ios.deployment_target = '12.0'
  s.swift_versions = [ '5.0' ]

  s.default_subspecs = 'Core', 'UI'

  s.subspec 'Core' do |core|
    core.source_files = 'Snabble/Core/**/*.swift'

    core.dependency 'GRDB.swift', '~> 5'
    core.dependency 'Zip', '~> 2'
    core.dependency 'OneTimePassword', '~> 3'
    core.dependency 'TrustKit', '~> 1'
    core.dependency 'KeychainAccess', '~> 4'
  end

  s.subspec 'UI' do |ui|
    ui.source_files = 'Snabble/UI/**/*.swift'

    ui.dependency 'Snabble/Core'
    ui.dependency 'SDCAlertView', '~> 12'
    ui.dependency 'ColorCompatibility'
    ui.dependency 'WCAG-Colors'
    ui.dependency 'DeviceKit', '~> 4'
    ui.dependency 'Pulley', '~> 2.9'
    ui.dependency 'AutoLayout-Helper'

    ui.resource_bundles = {
      "Snabble" => [
        'Snabble/UI/*.lproj/*.strings',
        'Snabble/UI/**/*.xib',
        'Snabble/UI/**/*.der',
        'Snabble/UI/**/*.html',
        'Snabble.xcassets'
      ]
    }
  end

  s.subspec 'Datatrans' do |dt|
    dt.dependency 'Snabble/UI'
    dt.dependency 'Datatrans'

    dt.source_files = 'Snabble/Datatrans/**/*.swift'

    dt.resource_bundles = {
       "SnabbleDT" => [ 'Snabble/Datatrans/**/*.xib' ]
    }
  end

end
