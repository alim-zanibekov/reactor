# Reactor
[![Codemagic build status](https://api.codemagic.io/apps/601dd98d83016c22056b904e/601dd98d83016c22056b904d/status_badge.svg)](https://codemagic.io/apps/601dd98d83016c22056b904e/601dd98d83016c22056b904d/latest_build)

JoyReactor mobile client

#### Screenshots


![photo_2022-02-22 23 56 27](https://user-images.githubusercontent.com/19346040/155218219-ee7cd220-4782-4cb9-8e74-06ec6e796923.jpeg) | ![photo_2022-02-22 23 56 23](https://user-images.githubusercontent.com/19346040/155218223-a701d8bf-fcb4-414e-a0be-6142f4c59521.jpeg) | ![photo_2022-02-22 23 56 28](https://user-images.githubusercontent.com/19346040/155218217-fa795bb7-fd2e-4475-817e-965fdf15ec98.jpeg) | ![photo_2022-02-22 23 56 22](https://user-images.githubusercontent.com/19346040/155218225-180ae0f1-9abf-4c3e-bb74-31ed35470f3e.jpeg) | ![photo_2022-02-22 23 58 06](https://user-images.githubusercontent.com/19346040/155218200-83f8b364-60fc-41a5-a70a-410111ae4525.jpeg)
|-|-|-|-|-|
![photo_2022-02-22 23 56 33](https://user-images.githubusercontent.com/19346040/155218209-7894c6f1-0c12-4e35-a9d7-fa67d315dca2.jpeg) | ![photo_2022-02-22 23 58 05](https://user-images.githubusercontent.com/19346040/155218205-8ca2d874-a58c-4d1d-8693-70de281b8f68.jpeg) | ![photo_2022-02-23 00 06 09](https://user-images.githubusercontent.com/19346040/155219462-1e9d6d93-d157-4118-b80d-9ab83303e9e1.jpeg) | ![photo_2022-02-22 23 56 32](https://user-images.githubusercontent.com/19346040/155218210-7d929ffd-185e-48fa-8ceb-d274a80ab63f.jpeg) | ![photo_2022-02-22 23 56 31](https://user-images.githubusercontent.com/19346040/155218213-869ac334-259b-4262-bbbc-859b8e837067.jpeg) 

#### Demo (real device: Android, Snapdragon 855, 6gb RAM)

https://user-images.githubusercontent.com/19346040/155216497-485d7836-c0e0-45fa-bf89-04aa5c9fbc75.mp4


#### Installation

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
