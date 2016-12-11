Pod::Spec.new do |s|
  s.name         = "KKPuzzles"
  s.version      = "0.9.0"
  s.summary      = "A simple Jigsaw puzzle game."
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = "Krzysztof Kuc"
  s.homepage     = "https://github.com/kkuc/KKPuzzles"
  s.platform     = :ios
  s.source       = { :git => "https://github.com/kkuc/KKPuzzles.git", :tag => "#{s.version}" }
  s.source_files = "KKPuzzles", "KKPuzzles/**/*.{h,m}"
  s.dependency     "EKTilesMaker"
end
