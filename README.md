# api_request_helper_flutter

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

Api Request Helper Flutter is a repository that handles http calls such as GET, POST, PUT, DELETE

## Usage
To use this plugin, add `api_request_helper_flutter` as a [dependency in your pubspec.yaml file](https://flutter.dev/platform-plugins/).

## Running the script file.
Before running the script, make sure the permission is correct:
```
chmod +x script.sh
```

To run the script file:
```
./script.sh
```

### Reset Dependencies
This function remove the `pubspec.lock` and do `flutter clean` and `flutter pub get`.

### Code generation
This function generate code with build_runner, mainly use to generate mock file for tests.

### Format, Analyze & Test
This function mimics what will happen when the [VeryGoodWorkflow][very_good_workflow_flutter_package] runs on GitHub Actions.

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
