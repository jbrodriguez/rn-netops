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

#### Windows

[Read it! :D](https://github.com/ReactWindows/react-native)

1.  In Visual Studio add the `RNNetOps.sln` in `node_modules/rn-netops/windows/RNNetOps.sln` folder to their solution, reference from their app.
2.  Open up your `MainPage.cs` app

*   Add `using Net.Ops.RNNetOps;` to the usings at the top of the file
*   Add `new RNNetOpsPackage()` to the `List<IReactPackage>` returned by the `Packages` method

## Usage

```javascript
import RNNetOps from 'rn-netops'

// TODO: What to do with the module?
RNNetOps
```
