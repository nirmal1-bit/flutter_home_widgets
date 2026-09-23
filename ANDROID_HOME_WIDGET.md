# Interactive Android photoelectric-effect flashcards

This project contains a five-card Android home-screen study widget and a
separate image widget and a Japanese cloze-test widget built with
Flutter and [`home_widget`](https://pub.dev/packages/home_widget). It is based
on [Building Interactive Android HomeScreen Widgets with Flutter using
`home_widget`](https://buildwithshubham.medium.com/building-interactive-android-homescreen-widgets-with-flutter-using-home-widget-d7d423882455),
but uses the current `home_widget: ^0.10.0` API.

Each card has a question and answer. The user must reveal the answer before
the **Next card** action becomes available. The current card index and reveal
state are shared between the Flutter app and the Android launcher widget. The
second widget displays a formula image selected from the Flutter app. The
third widget shows Japanese sentences with English translations and three
answer choices. A wrong answer keeps the same card and shows an error marker;
only a correct answer unlocks the next card.

## Cards included

1. Einstein's equation: `Kₘₐₓ = hf − φ`, `Kₘₐₓ = eVₛ`.
2. Threshold frequency: `f₀ = φ / h`.
3. Effect of intensity: photocurrent changes, but `Kₘₐₓ` does not.
4. Effect of frequency: `Kₘₐₓ` and stopping voltage increase.
5. Threshold wavelength: `λ₀ = hc / φ`.

## Architecture

Flutter cannot render an ordinary Flutter widget directly in the Android
launcher. Android renders this widget through `RemoteViews`, so the feature is
split between Dart state and native Kotlin/XML UI:

```text
Flutter app ──saveWidgetData──> home_widget storage <──HomeWidgetProvider── widget
       │                              ▲                         │
       └──updateWidget────────────────┘                         │
                           reveal/next tap ──> Dart callback ───┘
```

The shared keys are:

```text
flashcard_index     current card, from 0 through 4
flashcard_revealed  whether the answer is visible
```

## Files

```text
lib/main.dart
android/app/src/main/AndroidManifest.xml
android/app/src/main/kotlin/com/example/widgets_testing/HomeScreenWidgetProvider.kt
android/app/src/main/kotlin/com/example/widgets_testing/StudyImageWidgetProvider.kt
android/app/src/main/kotlin/com/example/widgets_testing/JapaneseClozeWidgetProvider.kt
android/app/src/main/res/layout/widget_layout.xml
android/app/src/main/res/layout/study_image_widget_layout.xml
android/app/src/main/res/layout/japanese_cloze_widget_layout.xml
android/app/src/main/res/xml/widget_info.xml
android/app/src/main/res/xml/study_image_widget_info.xml
android/app/src/main/res/xml/japanese_cloze_widget_info.xml
android/app/src/main/res/drawable/widget_background.xml
```

## Dart implementation

The flashcards are declared in `lib/main.dart`. The top-level callback handles
the two URI actions sent by Android:

```dart
@pragma('vm:entry-point')
Future<void> interactiveCallback(Uri? uri) async {
  var index = await HomeWidget.getWidgetData<int>(
    'flashcard_index',
    defaultValue: 0,
  );
  var revealed = await HomeWidget.getWidgetData<bool>(
    'flashcard_revealed',
    defaultValue: false,
  );

  if (uri?.host == 'reveal') {
    revealed = true;
  } else if (uri?.host == 'next' && revealed == true) {
    index = ((index ?? 0) + 1) % flashcards.length;
    revealed = false;
  } else {
    return;
  }

  await HomeWidget.saveWidgetData('flashcard_index', index);
  await HomeWidget.saveWidgetData('flashcard_revealed', revealed);
  await HomeWidget.updateWidget(name: 'HomeScreenWidgetProvider');
}
```

`@pragma('vm:entry-point')` keeps the callback available in release builds,
including when Android invokes it while the Flutter UI is not running. Register
it before `runApp`:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(interactiveCallback);
  runApp(const MyApp());
}
```

The app page uses the same two storage keys. It reloads them when it starts,
when the app resumes, and when `HomeWidget.widgetClicked` emits an event. Its
Flutter **Reveal answer** and **Next card** buttons call the same save/update
flow as the launcher widget.

## Image widget

The app includes a **Set an image widget** section with three built-in formula
images. Selecting one calls `HomeWidget.renderFlutterWidget`, which converts a
Flutter `StudyImageCard` into a PNG and stores its file path under
`selected_study_image`. The selected title is stored under
`selected_study_image_title`, and only the second widget is refreshed:

```dart
await HomeWidget.renderFlutterWidget(
  StudyImageCard(title: title, formula: formula),
  logicalSize: const Size(320, 180),
  key: 'selected_study_image',
);
await HomeWidget.saveWidgetData<String>(
  'selected_study_image_title',
  title,
);
await HomeWidget.updateWidget(name: 'StudyImageWidgetProvider');
```

`StudyImageWidgetProvider.kt` reads the saved PNG path, decodes it into a
bitmap, and places it in an Android `ImageView`. This is why the image can be
changed from the app without shipping a separate Android drawable for every
choice. The image widget initially shows a placeholder until the first image
is selected.

To use your own images, replace the `_studyImages` choices and customize
`StudyImageCard`. For image files bundled as Flutter assets, load the asset
with `rootBundle`, then use `HomeWidget.saveFile` with a PNG/JPEG extension and
store the returned path under `selected_study_image`.

## Japanese cloze widget

The Japanese widget contains five beginner sentences, their English
translations, and three Japanese choices. Its shared state is:

```text
japanese_cloze_index     current sentence, from 0 through 4
japanese_cloze_feedback  empty, wrong, or correct
japanese_cloze_attempts  number of wrong attempts on the current sentence
```

Each choice sends an action such as
`widgetsTesting://japanese_option_0`. The Dart callback compares that option
with the card's correct answer, saves either `wrong` or `correct`, and refreshes
`JapaneseClozeWidgetProvider`. A `japanese_next` action is ignored unless the
stored feedback is `correct`, so the learner cannot skip a card.

The Flutter app uses the same rules. A wrong answer changes the card tint and
shows a red cancel marker with “Not quite — wrong answer 1”, then “wrong answer 2”
for subsequent attempts, without changing the choice-button colors. A correct answer
shows a green check marker and unlocks **Next Japanese card**. The Android
widget uses the same feedback text and counter. After a
correct answer, both the Flutter app and widget replace the Japanese blank with
the selected word, showing the completed Japanese sentence with its English
translation. The next button remains disabled until that correct answer.

## Kotlin provider

`HomeScreenWidgetProvider.kt` extends `HomeWidgetProvider`. On every update it:

1. Reads the current index and reveal state from the shared preferences.
2. Chooses one of the five native card entries.
3. Shows or hides the answer using `RemoteViews`.
4. Disables **Next card** until the answer is revealed.
5. Attaches `widgetsTesting://reveal` and `widgetsTesting://next` pending
   intents.

The provider name must match the Dart update call:

```dart
HomeWidget.updateWidget(name: 'HomeScreenWidgetProvider');
```

The Kotlin card list intentionally mirrors the Dart card list. Android needs a
native copy because the launcher cannot execute Flutter UI code just to render
the widget.

## Widget layout and metadata

`res/layout/widget_layout.xml` is a `RemoteViews` layout containing:

- progress text (`Card 1 of 5`);
- the question;
- answer label and answer text;
- **Reveal answer** and **Next card** buttons.

`res/xml/widget_info.xml` declares the minimum widget size and allows horizontal
and vertical resizing. `widget_background.xml` provides the rounded card
background.

RemoteViews supports a limited set of Android views. Do not replace this XML
with arbitrary Flutter widgets or custom Android views without checking Android
widget support.

## Manifest registration

The main manifest registers the provider:

```xml
<receiver
    android:name=".HomeScreenWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/widget_info" />
</receiver>
```

It also registers `HomeWidgetBackgroundReceiver`, which receives the native
button broadcasts and forwards them to the registered Dart callback.
The `StudyImageWidgetProvider` is registered separately, so both widgets appear
in the Android widget picker.
The `JapaneseClozeWidgetProvider` is registered separately as well, so all
three widgets appear in the picker.

## Run and test

Use an Android emulator or physical device with a launcher that supports app
widgets:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Then:

1. Long-press an empty area of the Android home screen.
2. Choose **Widgets**.
3. Drag the `widgets_testing` widget to the home screen.
4. Press **Reveal answer**.
5. Press **Next card** to move to the next question.
6. Open the app and verify that it displays the same card and reveal state.
7. In the app, choose one of the formula images under **Set an image widget**.
8. Add **StudyImageWidget** from the widget picker and verify that it shows the
   selected image. Choose another image in the app to refresh it.
9. Add **JapaneseClozeWidget** from the widget picker.
10. Select an incorrect choice and verify that the card does not advance.
11. Select the correct choice, then press **Next card**.

After changing Kotlin, XML, or the manifest, perform a full rebuild or
reinstall. Hot reload does not re-register Android widget metadata.

## Troubleshooting

If the widget does not appear, uninstall and reinstall the app and check that
`widget_info.xml` is under `android/app/src/main/res/xml/`.

If **Next card** stays disabled, reveal the answer first. This is intentional
and is enforced both in the widget UI and in the Dart callback.

If the app and widget disagree, verify that both use exactly
`flashcard_index`, `flashcard_revealed`, and `HomeScreenWidgetProvider`.

If release taps do nothing, confirm that the callback is top-level, registered
before `runApp`, and has the `@pragma('vm:entry-point')` annotation.
