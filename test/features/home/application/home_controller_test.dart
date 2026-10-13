import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/core/error/app_exception.dart';
import 'package:paw_care_app/features/home/application/home_controller.dart';
import 'package:paw_care_app/features/home/domain/models/health_record_summary.dart';

import '../../../helpers/fake_home_repository.dart';

void main() {
  final record = HealthRecordSummary(
    id: 'record-id',
    recordType: 'symptom',
    description: '食欲下降',
    recordDate: DateTime(2026, 10, 13),
  );

  test('loads recent records once for the current pet', () async {
    final repository = FakeHomeRepository(records: [record]);
    final controller = HomeController(repository: repository);
    addTearDown(controller.dispose);

    await controller.loadForPet('pet-id');
    await controller.loadForPet('pet-id');

    expect(controller.status, HomeSummaryStatus.ready);
    expect(controller.recentRecords, [record]);
    expect(repository.calls, 1);
    expect(repository.lastPetId, 'pet-id');
  });

  test('reloads when the current pet changes', () async {
    final repository = FakeHomeRepository();
    final controller = HomeController(repository: repository);
    addTearDown(controller.dispose);

    await controller.loadForPet('pet-a');
    await controller.loadForPet('pet-b');

    expect(repository.calls, 2);
    expect(repository.lastPetId, 'pet-b');
  });

  test('keeps an error state and clears it when no pet is selected', () async {
    final repository = FakeHomeRepository()
      ..error = const NetworkException('网络不可用');
    final controller = HomeController(repository: repository);
    addTearDown(controller.dispose);

    await controller.loadForPet('pet-id');

    expect(controller.status, HomeSummaryStatus.failure);
    expect(controller.error, isA<NetworkException>());

    controller.clear();

    expect(controller.status, HomeSummaryStatus.idle);
    expect(controller.recentRecords, isEmpty);
    expect(controller.error, isNull);
  });
}
