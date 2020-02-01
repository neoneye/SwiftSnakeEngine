source 'https://github.com/CocoaPods/Specs.git'
swift_version = "5.0"
platform :osx, '10.14'
use_frameworks!

def my_pod_swiftcsv
	# https://github.com/swiftcsv/SwiftCSV/commits/master
	pod 'SwiftCSV', :git => 'https://github.com/swiftcsv/SwiftCSV.git', :commit => '22dc4dd1272e990da64ea87a8bc84bb606eb177e'
end

def my_pod_swiftprotobuf
	# https://github.com/apple/swift-protobuf/commits/master
	pod 'SwiftProtobuf', :git => 'https://github.com/apple/swift-protobuf.git', :commit => 'b2baf41e0d62cccda25d12e18e9b1660756a8d4a'
end

def my_pod_sseventflow
	# https://github.com/neoneye/SSEventFlow/commits/master
	pod 'SSEventFlow', :git => 'https://github.com/neoneye/SSEventFlow.git', :commit => 'f81413764a7cece32e5ffb1601a41f31884c1f88'
end

abstract_target 'BasePods' do
	target 'SnakeGameTests' do
	end

	target 'SnakeGame' do
		my_pod_swiftcsv
		my_pod_swiftprotobuf
	end

	target 'AppMac' do
		my_pod_sseventflow
	end
end
