StreamHub-iOS-Reviews-App
=========================


First clone the repo:

    cd ~/dev
    git clone https://github.com/Livefyre/StreamHub-iOS-Reviews-App.git
    cd StreamHub-iOS-Reviews-App

If you don't have CocoaPods installed, install CocoaPods:

    sudo gem install cocoapods
    pod setup

Make sure to set up our custom CocoaPod repo

    pod repo add escherba https://github.com/escherba/Specs.git

Finally:

    pod install
    open CommentStream.xcworkspace
