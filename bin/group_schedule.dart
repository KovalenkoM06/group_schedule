import 'dart:async';

import 'package:group_schedule/group_schedule.dart';

/// Точка входу консольної програми для лабораторної роботи №3.
Future<void> main(List<String> arguments) async {
  final validLessons = parseValidLessons(rawScheduleInput);
  final asyncRepo = AsyncRepository<Lesson>(
    operationDelay: const Duration(milliseconds: 20),
  );
  await asyncRepo.saveAll(validLessons.take(4));

  print('=== 1. Помилка "забутий await" та AsyncRepository ===');
  final (:countBeforeAwait, :countAfterAwait) = await demonstrateForgottenAwait(
    validLessons.first,
  );
  print(
    'Кількість елементів одразу після save() без await: $countBeforeAwait, '
    'після await: $countAfterAwait',
  );
  final loadedFirst = await asyncRepo.load(validLessons.first.id);
  print('Завантажено за id: ${loadedFirst?.subject} (${loadedFirst?.room})');

  print('');
  print(
    '=== 2. Порівняння послідовного та одночасного виконання (3 x 500 мс) ===',
  );
  final (:sequentialMs, :parallelMs) = await measureSequentialVsParallel(
    validLessons,
  );
  print('Послідовні await (3 операції по 500 мс): $sequentialMs мс');
  print('Одночасно через Future.wait (3 операції по 500 мс): $parallelMs мс');

  print('');
  print(
    '=== 3. Обробка помилок групи (Future.wait vs .wait / ParallelWaitError) ===',
  );
  final (:futureWaitInfo, :parallelWaitInfo) = await compareGroupErrorHandling(
    validLessons,
  );
  print('  • $futureWaitInfo');
  print('  • $parallelWaitInfo');

  print('');
  print('=== 4. Неспіймана асинхронна помилка (try/catch без await) ===');
  final (:caughtByTryCatch, :zoneError) = await demonstrateUncaughtAsyncError();
  print(
    'Спіймано синхронним try/catch: $caughtByTryCatch | '
    'Перехоплено зоною: $zoneError',
  );

  print('');
  print('=== 5. Генератор async* (watchAll), доказ лінивості та await for ===');
  final lazyStream = asyncRepo.watchAll(
    interval: const Duration(milliseconds: 15),
    logStart: true,
  );
  print('  [main] Потік watchAll() створено, але підписки ще немає...');
  await for (final lesson in lazyStream) {
    print('  [await for] Отримано: ${lesson.subject} (${lesson.type})');
  }

  print('');
  print(
    '=== 6. Буферизація StreamController (3 події ДО підписки) та listen() ===',
  );
  final bufferedEvents = await demonstrateBufferedControllerListen(
    validLessons,
  );
  for (final event in bufferedEvents) {
    print('  [listen] $event');
  }

  print('');
  print(
    '=== 7. Помилка всередині потоку: await for vs listen(cancelOnError: false) ===',
  );
  final (:awaitForLog, :listenLog) = await compareMidStreamErrorHandling(
    asyncRepo,
  );
  print('  Режим await for:');
  for (final entry in awaitForLog) {
    print('    - $entry');
  }
  print('  Режим listen (cancelOnError: false):');
  for (final entry in listenLog) {
    print('    - $entry');
  }

  print('');
  print('=== 8. Потік одноразової підписки vs широкомовний (broadcast) ===');
  final (
    :singleSubscriptionError,
    :broadcastFirstCount,
    :broadcastSecondCount,
  ) = await compareSingleAndBroadcastStreams(
    validLessons,
  );
  print('  Повторна підписка на одноразовий потік: $singleSubscriptionError');
  print(
    '  Широкомовний потік (2 підписники): '
    'перший отримав $broadcastFirstCount події, другий — $broadcastSecondCount події',
  );

  print('');
  print('=== 9. Конвеєр трансформації потоку (where -> map -> take) ===');
  final sourceEvents = Stream<ScheduleEvent>.fromIterable(
    validLessons.map(
      (lesson) => ScheduleEvent(action: 'РОЗКЛАД', lesson: lesson),
    ),
  );
  await for (final formatted in buildScheduleEventPipeline(sourceEvents)) {
    print('  [pipeline] $formatted');
  }

  print('');
  print(
    '=== 10. Важке обчислення в Isolate.run та ізоляція глобальної змінної ===',
  );
  final (
    :mainIsolateMs,
    :workerIsolateMs,
    :sequentialTwoTasksMs,
    :parallelTwoIsolatesMs,
    :digest,
    :globalBefore,
    :globalInsideWorker,
    :globalAfterInMain,
  ) = await benchmarkScheduleIsolate(
    validLessons,
  );
  print(
    '  Одне обчислення (контрольна сума $digest): '
    'головний ізолят = $mainIsolateMs мс, Isolate.run = $workerIsolateMs мс',
  );
  print(
    '  Два важкі обчислення: '
    'послідовно в головному = $sequentialTwoTasksMs мс, '
    'паралельно у двох Isolate.run = $parallelTwoIsolatesMs мс',
  );
  print(
    '  Глобальна змінна globalIsolateProbe: '
    'до запуску = $globalBefore, змінено в ізоляті на = $globalInsideWorker, '
    'у головному ізоляті після завершення = $globalAfterInMain',
  );
}
