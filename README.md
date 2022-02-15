# Reactor

JoyReactor mobile client

0. Install flutter [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)

1. Apply monkey patch: `./patch/apply.sh` *

2. Install dependencies `flutter pub get` 

3. Connect your device or launch emulator (`flutter emulators` and `flutter emulators --launch [emulator name]`)

4. Get available devices: `flutter devices`

5. Select iOS or Android device and run with device id
```shell
flutter run --profile -d [device-id]
```

6. Revert monkey patch: `./patch/apply.sh r`

<sup>* Patch removes Scrollable wrapper around EditableText widget because it causes unnecessary text slide down animation</sup>