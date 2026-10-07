import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hajicare/features/money/screens/money_recognition_screen.dart';

class MockImagePicker extends Fake implements ImagePicker {
  final XFile? mockResult;
  bool pickImageCalled = false;
  ImageSource? capturedSource;

  MockImagePicker({this.mockResult});

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    pickImageCalled = true;
    capturedSource = source;
    return mockResult;
  }
}

void main() {
  group('Money Recognition - Gallery Option Integration Tests', () {
    test('MoneyRecognitionScreen accepts injected ImagePicker dependency', () {
      final mockPicker = MockImagePicker();
      final screen = MoneyRecognitionScreen(imagePicker: mockPicker);
      expect(screen.imagePicker, equals(mockPicker));
    });

    test('MockImagePicker correctly returns mock image data from gallery', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final mockFile = XFile.fromData(
        sampleBytes,
        name: 'money_sample.jpg',
        mimeType: 'image/jpeg',
      );
      final mockPicker = MockImagePicker(mockResult: mockFile);

      final result = await mockPicker.pickImage(source: ImageSource.gallery);
      expect(mockPicker.pickImageCalled, isTrue);
      expect(mockPicker.capturedSource, equals(ImageSource.gallery));
      expect(result, isNotNull);

      final bytes = await result!.readAsBytes();
      expect(bytes, equals(sampleBytes));
    });
  });
}
