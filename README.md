# Flutter Home Widgets Study App

An Android Flutter learning app with three interactive home-screen widgets
powered by [`home_widget`](https://pub.dev/packages/home_widget):

1. **Photoelectric Effects Flashcards** — reveal a formula or explanation, then
   move to the next card.
2. **Study Image Widget** — choose a formula image in the Flutter app and show
   it on the Android home screen.
3. **Japanese Cloze Widget** — complete Japanese sentences using multiple
   choice answers, with English translations and progress locked until the
   answer is correct.

The project demonstrates how Flutter state can be shared with Android's native
home-screen widget system while keeping the widget UI native and lightweight.

## What the app looks like conceptually

```text
Flutter app
   │
   ├── shared values through home_widget
   │
   └── Android launcher widgets
       ├── Photoelectric flashcards
       ├── Formula image widget
       └── Japanese cloze quiz
```

Android home-screen widgets are rendered with `RemoteViews`, not regular
Flutter widgets. The Kotlin providers and XML layouts therefore live under
`android/app/src/main`, while Dart owns the shared data and background actions.

## Features

### Photoelectric-effect flashcards

The app includes five cards covering:

- Einstein's photoelectric equation: `Kₘₐₓ = hf − φ`
- stopping potential: `Kₘₐₓ = eVₛ`
- threshold frequency: `f₀ = φ / h`
- the effects of intensity and frequency
- threshold wavelength: `λ₀ = hc / φ`

In the Flutter app, the answer uses a horizontal flip animation. In the
launcher widget, **Reveal answer** updates the native view. **Next card** stays
disabled until the answer is revealed.

### Selectable formula image widget

The app has a **Set an image widget** section. Selecting a formula:

1. Builds a Flutter `StudyImageCard`.
2. Renders that widget to a PNG with `HomeWidget.renderFlutterWidget`.
3. Stores the generated file path in widget storage.
4. Refreshes `StudyImageWidgetProvider`.

The native provider decodes the PNG into an Android `ImageView`. To add more
images, update `_studyImages` and the `StudyImageCard` design in
`lib/main.dart`.

### Japanese cloze quiz

The Japanese widget contains five beginner sentences, English translations,
and three choices per sentence. For example:

```text
わたしは ___ です。
I am a student.

学生   先生   猫
```

An incorrect option shows a red error marker and keeps the current card. A
wrong-attempt counter is shown in the app and widget. A correct option shows a green success marker and unlocks
**Next card**. This rule is enforced in both the Flutter UI and the background
callback, so the launcher widget cannot skip a question. Once correct, the
Japanese blank is replaced with the selected word, showing the completed
Japanese sentence beside its English translation.

## Important project files

```text
lib/main.dart
android/app/src/main/AndroidManifest.xml
android/app/src/main/kotlin/com/example/widgets_testing/
  HomeScreenWidgetProvider.kt
  StudyImageWidgetProvider.kt
  JapaneseClozeWidgetProvider.kt
android/app/src/main/res/layout/
  widget_layout.xml
  study_image_widget_layout.xml
  japanese_cloze_widget_layout.xml
android/app/src/main/res/xml/
  widget_info.xml
  study_image_widget_info.xml
  japanese_cloze_widget_info.xml
ANDROID_HOME_WIDGET.md
```

`ANDROID_HOME_WIDGET.md` contains the detailed implementation notes, storage
keys, callback flow, setup details, and troubleshooting guide.

## Getting started

Install Flutter and an Android emulator or physical Android device, then run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

To add a widget:

1. Install and launch the app once.
2. Long-press an empty area of the Android home screen.
3. Select **Widgets**.
4. Add one of the three widgets.

After changing Kotlin, XML, or `AndroidManifest.xml`, perform a full rebuild or
reinstall. Hot reload does not re-register Android widget metadata.

## Building an APK

```bash
flutter build apk --debug
```

The generated debug APK is written to:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Widget data flow

The widgets use these storage keys:

```text
flashcard_index            current photoelectric card
flashcard_revealed         whether the flashcard answer is visible
selected_study_image       generated PNG path for the image widget
selected_study_image_title title shown by the image widget
japanese_cloze_index       current Japanese card
japanese_cloze_feedback    empty, wrong, or correct
japanese_cloze_attempts    number of wrong attempts on the current card
```

Widget button taps are converted into URI actions such as:

```text
widgetsTesting://reveal
widgetsTesting://next
widgetsTesting://japanese_option_0
widgetsTesting://japanese_next
```

The top-level Dart callback receives those URIs, updates shared data, and asks
the matching native provider to redraw.

## License

This is a learning project. Adapt the code and card content for your own use.
