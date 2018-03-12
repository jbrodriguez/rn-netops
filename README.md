# rn-netops

## Getting started

`$ npm install rn-netops --save`

### Mostly automatic installation

`$ react-native link rn-netops`

### Manual installation

#### iOS

1.  In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2.  Go to `node_modules` ➜ `rn-netops` and add `RNNetOps.xcodeproj`
3.  In XCode, in the project navigator, select your project. Add `libRNNetOps.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4.  Run your project (`Cmd+R`)<

#### Android

1.  Open up `android/app/src/main/java/[...]/MainActivity.java`

*   Add `import com.reactlibrary.RNNetOpsPackage;` to the imports at the top of the file
*   Add `new RNNetOpsPackage()` to the list returned by the `getPackages()` method

2.  Append the following lines to `android/settings.gradle`:
    ```
    include ':rn-netops'
    project(':rn-netops').projectDir = new File(rootProject.projectDir, 	'../node_modules/rn-netops/android')
    ```
3.  Insert the following lines inside the dependencies block in `android/app/build.gradle`:
    ```
      compile project(':rn-netops')
    ```

## Usage

```javascript
import NetOps from 'rn-netops'

NetOps.

    // ipv4
    ipAddress: ()

    // ping packet
    ping: (url, timeout)

    // wol packet
    wake: (mac, ip)

    // socket connection
    poke: (host, port, timeout)

    // Create an HTTP request.
    // @param  {string} url Request target url string.
    // @param  {object} options Configuration options for the fetch request, which can be.
    // 		@param  {string} method HTTP method, should be `GET`, `POST`, `PUT`, `DELETE`
    // 		@param  {object} headers HTTP request headers.
    // 		@param  {string} body HTTP request body.
    // 		@param  {boolean} cacheImage Use the url as a cache key (md5'd) and use a png
    //			extension for the file.
    // 		@param  {number} timeout Request timeout in millionseconds.
    // 		@param  {boolean} trusty If true, the request can be made against self-signed certs.
    fetch: (url, options)
```

## Credits

Inspired by

*   [react-native-fetch-blob](https://github.com/wkh237/react-native-fetch-blob)
*   [react-native-network-info](https://github.com/pusherman/react-native-network-info)

## License

MIT
