# Offscreen rendering with CEF and Metal

This project is a POC  work to combine CEF offsreen rendering on MacOS with Metal API. It was created based on the `cefsimple` test  found in the CEF distribution. 

The app creates a single window with an ever changing background color and a CEF texture on the top of it. Transparent areas of the browser window uncover
the animated background behind it.

## About CEF in general
Check the documentation at https://bitbucket.org/chromiumembedded/cef/wiki/GeneralUsage


## Setting it up
You need to download and extract the CEF binaries and set it up so that it creates an xcode project file that is referred by the `testapp.xcodeproj`. 
It was tested to work with `cef_binary_86.0.21+g6a2c8e7+chromium-86.0.4240.183_macosx64.tar.bz2`.

1. Download the CEF binaries

- https://cef-builds.spotifycdn.com/index.html#macosx64
- macos 64-bit
- select "standard distribution"

2. Extract into the `cef` folder

3. Follow the instructions in `cef/README.txt` and `cef/CMakeLists.txt` to create a `build` folder inside the `cef` directiory with `cef.xcodeproj`

4. Open `testapp.xcodeproj` in xcode, select the `testapp` target at run the project.

Enjoy your psychedelic spaceship trip.

![Spaceship](./spaceship.gif "Spaceship")
