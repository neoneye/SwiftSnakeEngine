source 'https://github.com/CocoaPods/Specs.git'
swift_version = "5.0"
use_frameworks!

def my_shared_pods
	# https://github.com/SwiftyBeaver/SwiftyBeaver/commits/master
	pod 'SwiftyBeaver', :git => 'https://github.com/SwiftyBeaver/SwiftyBeaver.git', :commit => '99057ecb615e7bb3145f68b8fdf85af1c8ae4af5'

	# https://github.com/swiftcsv/SwiftCSV/commits/master
	pod 'SwiftCSV', :git => 'https://github.com/swiftcsv/SwiftCSV.git', :commit => '22dc4dd1272e990da64ea87a8bc84bb606eb177e'

	# https://github.com/apple/swift-protobuf/commits/master
	pod 'SwiftProtobuf', :git => 'https://github.com/apple/swift-protobuf.git', :commit => 'd596aaf6568ff26285679e769769660a8b03b801'
end

def my_pod_sseventflow
	# https://github.com/neoneye/SSEventFlow/commits/master
	pod 'SSEventFlow', :git => 'https://github.com/neoneye/SSEventFlow.git', :commit => 'f81413764a7cece32e5ffb1601a41f31884c1f88'
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

	target 'SnakeGame' do
		my_shared_pods
	end

	target 'AppMac' do
		my_pod_sseventflow
	end
end
