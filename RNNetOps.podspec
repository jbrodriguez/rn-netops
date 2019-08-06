require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "RNNetOps"
  s.version      = package['version']
  s.summary      = package['description']
  s.license      = package['license']

  s.authors      = package['author']
  s.homepage     = "https://github.com/jbrodriguez/rn-netops"
  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/jbrodriguez/rn-netops.git", :tag => "v#{s.version}" }
  s.source_files  = "ios/**/*.{c,h,m}"

  s.dependency 'React'
end