#
# Be sure to run `pod lib lint Snabble.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name = 'Snabble'
  s.version = '0.22.0'
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
  s.module_name = 'SnabbleSDK'

  s.platform = :ios
  s.ios.deployment_target = '14.0'
  s.swift_versions = [ '5.0' ]

  s.default_subspecs = 'Core', 'UI'

  s.subspec 'Core' do |core|
    core.source_files = 'Snabble/Core/**/*.swift'

    core.dependency 'SwiftBase32', '~> 0.9.0'
    core.dependency 'GRDB.swift', '~> 5'
    core.dependency 'Zip', '~> 2'
    core.dependency 'OneTimePassword', '~> 3'
    core.dependency 'TrustKit', '~> 2'
    core.dependency 'KeychainAccess', '~> 4'
  end

  s.subspec 'UI' do |ui|
    ui.source_files = 'Snabble/UI/**/*.swift'

    ui.dependency 'Snabble/Core'
    ui.dependency 'SDCAlertView', '~> 12'
    ui.dependency 'WCAG-Colors'
    ui.dependency 'DeviceKit', '~> 4'
    ui.dependency 'Pulley', '~> 2.9'
    ui.dependency 'AutoLayout-Helper'

    ui.resource_bundles = {
      "SnabbleSDK" => [
        'Snabble/UI/*.lproj/*.strings',
        'Snabble/UI/*.lproj/*.stringsdict',
        'Snabble/UI/**/*.der',
        'Snabble/UI/**/*.html',
        'Snabble.xcassets'
      ]
    }
  end

  s.subspec 'Datatrans' do |dt|
    dt.dependency 'Snabble/UI'
    dt.dependency 'Datatrans', '~> 2.1.0'

    dt.source_files = 'Snabble/Datatrans/**/*.swift'
  end

end
