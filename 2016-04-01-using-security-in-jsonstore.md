---
title: Using Security in JSONStore
date: 2016-4-1
tags:
- iOS
- Android
- JSONStore
author:
  name: Nana Amfo
---



# Overview 
JSONStore  is a lightweight , document-oriented storage system that enables persistent storage of JSON documents for Android applications. Recently, this framework has been released as an open source framework. By default, the security features has been disabled. To enable the security features you will to do some few things to get security working. By the end of this blog you will have a JSONStore framework that is secured for your project.

## Android

### Native

#### Compilation


First unzip the **jsonstore_encryption.zip** file and pull out the `Android` folder. You should see `jniLibs`, `libs`, and `assets` subdirectories. 

Copy the contents of `libs` directory and paste them in your `libs` directory in your Anroid. Likewise, do the same for the `jniLibs` and `assets` directory. If you do not have an assets or jniLibs directory you can create them under `src/main`. 

In your build.gradle make sure the following are included as dependencies.

```Gradle
	compile fileTree(dir: 'libs', include: ['*.jar'])
    compile 'org.codehaus.jackson:jackson-jaxrs:1.9.13'
    compile 'com.google.guava:guava:14.0.1'
    compile 'com.ibm.mobilefirstplatform.clientsdk.android:jsonstore:+'
        
```

If you get errors like *duplicate files copied in APK META-INF/XXXX* add the following to your `build.gradle`.

```Gradle
	android {
		packagingOptions {
        	pickFirst 'META-INF/ASL2.0'
        	pickFirst 'META-INF/LICENSE'
        	pickFirst 'META-INF/NOTICE'
    	}
	}
```


![](https://developer.ibm.com/mobilefirstplatform/wp-content/uploads/sites/32/2016/03/Screen-Shot-2016-03-24-at-12.27.19-AM-271x300.png)

*Android Assets and jniLibs directory*

Finally, in your code you will need to call `JSONStore.getInstance(getApplicationContext()).setEncryption(true)` to enable encryption in your JSONStore application.


### Hybrid

#### Compilation

First, create a Cordova project. If you do not have Cordova you can install it [here](https://cordova.apache.org/).

```Bash
	cordova create ${ProjectName}
```

Next, install the Android platform and plugin.

```Bash
	cordova platform add android
	cordova plugin
```
Next, install the plugin

```Bash
	cordova install plugin cordova-plugin-jsonstore
```


As mentioned in the native portion, you will need to include the necessary `.so` and `.jar` files. 

#### Usage

In your code you will need to call the following in the begining of your code.

```Javascript
	JSONStore.setEncryption(true)
```


## iOS

### Native

#### Compiliation

First, add `SQLCipher.framework` and `libSQLCipherDatabase.a` to your `Link Binary to with Libraries` in the `Build Phases` tab. You can find these files under the `iOS` folder when you unzip **jsonstore_encryption.zip**.

#### Usage
In your code you will need to call 

```Objective-C
	[[JSONStore sharedInstance] setEncryption:YES];
```

### Hybrid

#### Compliation
Follow the instructions noted in the hybrid portion for Android but add the `ios` platform

```Bash
	cordova platform add ios
```

### Usage
Follow the instructions noted in the hybrid portion for Android