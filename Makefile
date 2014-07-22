.PHONY: clean

pods: Podfile
	pod install

clean:
	rm -rf Pods Podfile.lock *.xcworkspace
