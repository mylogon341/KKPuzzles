Pod::Spec.new do |s|
  s.name         = "KKPuzzles"
  s.version      = "1.0.0"
  s.summary      = "A short description of KKPuzzles."
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author       = "Krzysztof Kuc"
  s.homepage     = "https://bitbucket.org/kkuc93/kkpuzzle"
  s.platform     = :ios
  s.source       = { :git => "https://bitbucket.org/kkuc93/kkpuzzle.git", :tag => "#{s.version}" }
  s.source_files = "KKPuzzles", "KKPuzzles/**/*.{h,m}"
  s.dependency     "EKTilesMaker"
end
