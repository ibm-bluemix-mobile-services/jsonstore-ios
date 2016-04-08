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
JSONStore is a lightweight , document-oriented storage system that enables persistent storage of JSON documents for Android applications. Recently, this framework has been released as an open source framework. IBM MobileFirst Platform Foundation provides libraries that allow to enable security features such as encryption and FIPS support in JSONStore. By the end of this blog you will have a JSONStore framework that is secured for your project.

## Android applications

#### Installing JSONStore

In order to install JSONStore follow the step by step instructions described at [https://github.com/ibm-bluemix-mobile-services/jsonstore-android](https://github.com/ibm-bluemix-mobile-services/jsonstore-android)

#### Enabling encryption and FIPS support

First unzip the **jsonstore_encryption.zip** file and pull out the `Android` folder. You should see `jniLibs`, `libs`, and `assets` subdirectories. 

Copy the contents of `libs` directory and paste them in your `libs` directory in your Anroid. Likewise, do the same for the `jniLibs` and `assets` directory. If you do not have an assets or jniLibs directory you can create them under `src/main`. 

In your build.gradle make sure the following line is included under dependencies

```Gradle
compile fileTree(dir: 'libs', include: ['*.jar'])
```

Below screenshot shows the final file system layout after following the above instructions

![](EnablingJsonStoreSecurityAndroidStudio.png)

Once all the required libraries are in place the last remaining thing to do is to call below method to enable encryption in your JSONStore application.

```Java
JSONStore.getInstance(getApplicationContext()).setEncryption(true)
``` 
Now you can use JSONStoreInitOptions instance to set username and password for encrypting your JSONStore collections. 

> To ensure that FIPS compliant encryption is enabled look for the below text in LogCat output

> ```
> 04-08 19:56:42.566 13387-13387/? D/libuvpn: SSL Version=OpenSSL 1.0.1p-fips 9 Jul 2015
> 04-08 19:56:42.566 13387-13387/? D/libuvpn: SSL Version=OpenSSL 1.0.1p-fips 9 Jul 2015
> 04-08 19:56:42.626 13387-13387/? D/libuvpn:
> ------------------------------------------------------
> 											FIPS_mode initially 0, setting to 1
> 04-08 19:56:42.626 13387-13387/? D/libuvpn: FIPS_mode_set succeeded
> ------------------------------------------------------
> ```

## iOS applications

#### Installing JSONStore

In order to install JSONStore follow the step by step instructions described at [https://github.com/ibm-bluemix-mobile-services/jsonstore-ios](https://github.com/ibm-bluemix-mobile-services/jsonstore-ios)

#### Enabling encryption and FIPS support

First, add `SQLCipher.framework` and `libSQLCipherDatabase.a` to your `Link Binary with Libraries` in the `Build Phases` tab of your iOS project. You can find these files under the `iOS` folder when you unzip **jsonstore_encryption.zip**.

Once all the required files are added call the below method in your iOS application

```Objective-C
[[JSONStore sharedInstance] setEncryption:YES];
```

## Cordova applications

#### Installing JSONStore

In order to install JSONStore Cordova plugin follow the step by step instructions described at [https://github.com/ibm-bluemix-mobile-services/jsonstore-cordova](https://github.com/ibm-bluemix-mobile-services/jsonstore-cordova)

#### Enabling encryption and FIPS support

Follow the instructions for adding files for native application. Once all the required files are added call the below method in your Cordovaq application

```Javascript
JSONStore.setEncryption(true)
```
