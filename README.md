# Secuchat

<h3>To be updated soon<h3>

#[SecuChat Play Store Download](https://play.google.com/store/apps/details?id=com.developerik.secuchat)

#[SecuChat Github Downlod](https://github.com/ishu17077/secuChat/releases/latest)

## Getting Started With Documentation

The Project was made to improve the current privacy fiasco of chat apps.

We opened the source code so that you can audit our app and request for merge while making you in control of what we store about you. While we are working on shifting our current operations from firebase to own cloud, rest assured it would be done by in future.

A few resources to get you started if you want to build this app yourself.

- [Lab: Flutter](https://docs.flutter.dev/)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

We expect nothing less than respectful criticization while actively working on OUR(which includes but NOT LIMITED TO EVERYONE USING OR WORKING on it) APP.

## To build this app

### Download Flutter

[Flutter Installation Instructions](https://docs.flutter.dev/get-started/quick)

### Clone this repo

```bash
git clone https://github.com/ishu17077/SecuChat/
cd SecuChat
```

### Firebase Console Setup

> Now you have to go to firebase console and generate a new project(please change the package name as applicabole):
> Generating signing key
>> For windows

```bash
cd android
.\gradlew.bat signingReport
```

>> For Linux/Mac

```bash
cd android
chmod +x ./gradlew
./gradlew signingReport
```

Get the signing key, and get the first one that is displayed(Variant: debug):
Copy the hashes and paste the hash in the project creation step in firebase.

> Generate a new google services.json file and paste it in android/app module(directory)

> That's all, all you gotta do now is compile

> Install ADB Debug Bridge Drivers(Preferrably use Android Studio)

> Connect an emulator or your android device with USB Debugging configured

> Run this

```bash
flutter run
```
