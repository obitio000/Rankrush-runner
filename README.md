# Study Game Splash

This project contains the corrected Flutter splash/loading screen.

## Asset
The generated warrior artwork is already included as:

assets/images/archer_hero.png

## Run
flutter pub get
flutter run

## Build APK
flutter build apk --release

The design keeps the original black/red/neon-green composition, bottom loading section,
pulsing loading text, and moving arrow. The progress bar is drawn with CustomPainter
instead of Expanded(flex: 0), removing the layout issue in the original code.
