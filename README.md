StreamHub-iOS-Reviews-App
=========================

This is a sample app that demonstrates how to integrate Livefyre Reviews into your native iOS app. It uses StreamHub-iOS-SDK [[1]] to query Livefyre API.

Getting Started
---------------
If you haven't already, please install CocoaPods first [[2]]. You can do this
simply by running `gem install cocoapods` and `pod setup`. Once installed,
do the following (assuming you keep your projects in `~/dev` directory):

    cd ~/dev
    git clone https://github.com/Livefyre/StreamHub-iOS-Reviews-App.git
    cd StreamHub-iOS-Reviews-App
    pod install
    open LivefyreReviews.xcworkspace

Note that the `pod install` step above can take a minute or two. When done
installing, use `LivefyreReviews.xcworkspace` to open the project instead of the
`LivefyreReviews.xcproject` file.

Requirements
------------
StreamHub-SDK starting from v0.2 requires Xcode 5 and iOS 6.0 or later.

License
-------

This software is licensed under the MIT License.

The MIT License (MIT)

Copyright (c) 2013-2015 Livefyre

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[1]: https://github.com/Livefyre/StreamHub-iOS-SDK
[2]: http://guides.cocoapods.org/using/getting-started.html
