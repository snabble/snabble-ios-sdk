#
# Be sure to run `pod lib lint Snabble.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Snabble'
  s.version          = '0.9.17'
  s.summary          = 'The snabble iOS SDK'

  s.description      = <<-DESC
  snabble - the self-scanning and checkout platform
  The SDK provides scanning, checkout and payment services and UI components based on the snabble SaaS platform.
  DESC

  s.homepage         = 'https://snabble.io/'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'snabble GmbH' => 'info@snabble.io' }
  s.source           = { :git => 'https://github.com/snabble/iOS-SDK.git', :tag => "#{s.version}" }
  s.social_media_url = 'https://twitter.com/snabble_io'

  s.ios.deployment_target = '10.0'
  s.swift_version = '4.2'

  s.subspec 'Core' do |core|
    core.source_files = 'Snabble/Core/**/*.swift'
    core.dependency 'GRDB.swift', '~> 3'
    core.dependency 'Zip', '~> 1'
    core.dependency 'OneTimePassword', '~> 3'
    core.dependency 'TrustKit', '~> 1'
  end

  s.subspec 'UI' do |ui|
    ui.source_files = 'Snabble/UI/**/*.swift'
    ui.dependency 'Snabble/Core'

    ui.resource_bundles = {
      "Snabble" => [ 'Snabble.xcassets', 'Snabble/UI/*.lproj/*.strings', 'Snabble/UI/**/*.xib', 'i18n/*.twine' ]
    }

    if ENV["SNABBLE_POD"] == "dev"
      ui.script_phase = { :name => "Run twine", 
        :script => <<-SCRIPT
        if [ "$TESTING" -ne "1" ]; then
          if which twine >/dev/null; then
            cd $PODS_TARGET_SRCROOT
            TWINE=i18n/Snabble.twine
            if [ -r "$TWINE" ]; then
              echo "Creating strings file"
              twine generate-localization-file $TWINE --lang en --format apple Snabble/UI/en.lproj/SnabbleLocalizable.strings
            fi
          fi
        fi
        SCRIPT
      }
    end
  end

end
