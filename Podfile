source 'https://github.com/CocoaPods/Specs.git'
swift_version = "5.2"
use_frameworks!

def my_shared_pods
	# https://github.com/SwiftyBeaver/SwiftyBeaver/commits/master
	pod 'SwiftyBeaver', :git => 'https://github.com/SwiftyBeaver/SwiftyBeaver.git', :commit => '99057ecb615e7bb3145f68b8fdf85af1c8ae4af5'

	# https://github.com/swiftcsv/SwiftCSV/commits/master
	pod 'SwiftCSV', :git => 'https://github.com/swiftcsv/SwiftCSV.git', :commit => '22dc4dd1272e990da64ea87a8bc84bb606eb177e'

	# https://github.com/apple/swift-protobuf/commits/master
	pod 'SwiftProtobuf', :git => 'https://github.com/apple/swift-protobuf.git', :commit => 'd596aaf6568ff26285679e769769660a8b03b801'

  # https://github.com/adamcichy/SwiftySound/commits/master
  pod 'SwiftySound', :git => 'https://github.com/adamcichy/SwiftySound.git', :commit => 'de233cc96b0154cb26c66b9a0f1c2719709c83ac'

end

def my_pod_sseventflow
	# https://github.com/neoneye/SSEventFlow/commits/master
	pod 'SSEventFlow', :git => 'https://github.com/neoneye/SSEventFlow.git', :commit => '089bbf2707e046165a298a59e1fcc694a4042d82'
end

abstract_target 'BasePodsIOS' do
	platform :ios, '13.0'

	target 'EngineIOS' do
		my_shared_pods
	end

	target 'AppIOS' do
		my_pod_sseventflow
	end
end

abstract_target 'BasePodsMAC' do
	platform :macos, '10.15'

	target 'EngineMacTests' do
	end

	target 'EngineMac' do
		my_shared_pods
	end

	target 'AppMac' do
		my_pod_sseventflow
	end
end
