# SSEventFlow

[![Version](https://img.shields.io/cocoapods/v/SSEventFlow.svg?style=flat)](http://cocoapods.org/pods/SSEventFlow)
[![License](https://img.shields.io/cocoapods/l/SSEventFlow.svg?style=flat)](http://cocoapods.org/pods/SSEventFlow)
[![Platform](https://img.shields.io/cocoapods/p/SSEventFlow.svg?style=flat)](http://cocoapods.org/pods/SSEventFlow)

SSEventFlow is a type safe alternative to NSNotification, inspired by Flux.

The Flux Application Architecture was recently invented by Facebook.
[See video to how it works](https://facebook.github.io/flux/docs/in-depth-overview.html#content)


## Usage

Open the SSEventFlow.xcodeproj file and run the Example project.


## Requirements

- iOS 10.0+ / macOS 10.12+
- Xcode 10+
- Swift 4.2+


## Installation

SSEventFlow is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SSEventFlow"
```


## Example of how to send out notifications

```swift
class ParentViewController: UIViewController {
    @IBAction func redButtonAction(_ sender: Any) {
        PickedColorEvent(color: UIColor.red, name: "RED").fire()
    }
    @IBAction func greenButtonAction(_ sender: Any) {
        PickedColorEvent(color: UIColor.green, name: "GREEN").fire()
    }
    @IBAction func blueButtonAction(_ sender: Any) {
        PickedColorEvent(color: UIColor.blue, name: "BLUE").fire()
    }
    @IBAction func resetButtonAction(_ sender: Any) {
        ResetEvent().fire()
    }
}
```


## Example of how to listen for notifications

```swift
class ChildViewController: UIViewController {
    @IBOutlet weak var colorName: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        flow_start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        flow_stop()
        super.viewDidDisappear(animated)
    }
}

extension ChildViewController: FlowDispatcher {
    func flow_dispatch(_ event: FlowEvent) {
        if let e = event as? PickedColorEvent {
            view.backgroundColor = e.color
            colorName.text = e.name
        }
        if event is ResetEvent {
            view.backgroundColor = nil
            colorName.text = ""
        }
    }
}
```


# Support

You are welcome to use SSEventFlow free of charge. 

If you are using and enjoying my work, maybe you could donate me a beer (or if you don’t drink – 
a coffee and bagel will do just fine, a good kind of bagel though, you know… with wonderful stuff inside to make it glorious).

[Please donate via PayPal](https://paypal.me/SimonStrandgaard) and just like they say on TV – give generously! It motivates me to keep working on this.


# License

MIT
