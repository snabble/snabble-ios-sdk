#
# Be sure to run `pod lib lint Snabble.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name = 'Snabble'
  s.version = '0.13.7'
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
  s.ios.deployment_target = '10.3'
  s.swift_versions = [ '5.0' ]

  s.subspec 'Core' do |core|
    core.source_files = 'Snabble/Core/**/*.swift'

    core.dependency 'GRDB.swift', '~> 4'
    core.dependency 'Zip', '~> 1'
    core.dependency 'OneTimePassword', '~> 3'
    core.dependency 'TrustKit', '~> 1'
    core.dependency 'KeychainAccess', '~> 4'
  end

  s.subspec 'UI' do |ui|
    ui.source_files = 'Snabble/UI/**/*.swift'

    ui.dependency 'Snabble/Core'
    ui.dependency 'UIEmptyState', '~> 4'
    ui.dependency 'EasyTipView', '~> 2'
    ui.dependency 'SDCAlertView', '~> 11.1'

    ui.resource_bundles = {
      "Snabble" => [ 
        'Snabble.xcassets', 
        'Snabble/UI/*.lproj/*.strings', 
        'Snabble/UI/**/*.xib',
        'Snabble/UI/**/*.der',
        'i18n/*.twine' ]
    }
  end
end
