import 'package:flutter_test/flutter_test.dart';
import 'package:shiroguma_squeeze_app/services/pressure_processing_service.dart';

void main() {
  test('normalizes pressure into the calibrated MVS range', () {
    expect(
      PressureProcessingService.normalizePressure(
        pressure: 1500,
        baselinePressure: 1000,
        mvsPressure: 2000,
      ),
      0.5,
    );
  });

  test('assesses stable baseline samples', () {
    final result = PressureProcessingService.assessBaseline([1000, 1020, 1040]);

    expect(result.isStable, isTrue);
    expect(result.meanPressure, 1020);
    expect(result.range, 40);
  });

  test('rejects unstable baseline samples', () {
    final result = PressureProcessingService.assessBaseline([1000, 1100, 1120]);

    expect(result.isStable, isFalse);
    expect(result.reason, contains('hold device still'));
  });

  test('calculates MVS from upper squeeze region median', () {
    final result = PressureProcessingService.calculateMvs(
      baselinePressure: 1000,
      samples: [1010, 1300, 1480, 1500, 1520],
    );

    expect(result.valid, isTrue);
    expect(result.mvsPressure, 1500);
    expect(result.samplesUsed, 3);
  });

  test('rejects MVS samples with insufficient rise above baseline', () {
    final result = PressureProcessingService.calculateMvs(
      baselinePressure: 1000,
      samples: [1010, 1050, 1120],
    );

    expect(result.valid, isFalse);
    expect(result.reason, contains('less than 150 mbar'));
  });
}
