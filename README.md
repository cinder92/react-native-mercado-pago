
# react-native-mercado-pago

## Getting started

`$ npm install react-native-mercado-pago --save`

### Mostly automatic installation

`$ react-native link react-native-mercado-pago`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-mercado-pago` and add `RNMercadoPago.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNMercadoPago.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.cinder92.mercadopago.RNMercadoPagoPackage;` to the imports at the top of the file
  - Add `new RNMercadoPagoPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-mercado-pago'
  	project(':react-native-mercado-pago').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-mercado-pago/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-mercado-pago')
  	```


## Usage
```javascript
import RNMercadoPago from 'react-native-mercado-pago';

// TODO: What to do with the module?
RNMercadoPago;
```
  