import 'dart:async';

import 'package:group_schedule/group_schedule.dart';
import 'package:test/test.dart';

void main() {
  var repository = AsyncRepository<Lesson>(
    operationDelay: const Duration(milliseconds: 5),
  );
  var sampleLessons = <Lesson>[];

  setUp(() {
    Lesson.clearCache();
    sampleLessons = parseValidLessons(rawScheduleInput).take(3).toList();
    repository = AsyncRepository<Lesson>(
      operationDelay: const Duration(milliseconds: 5),
    );
  });

  group('AsyncRepository та обробка Future', () {
    test('save та load повертають збережене заняття за його id', () async {
      final first = sampleLessons.first;
      await repository.save(first);

      await expectLater(repository.load(first.id), completion(equals(first)));
    });

    test('load повертає null для відсутнього ідентифікатора', () async {
      await expectLater(repository.load('неіснуючий_id'), completion(isNull));
    });

    test('saveAll та delete коректно оновлюють перелік у loadAll', () async {
      await repository.saveAll(sampleLessons);
      final removed = await repository.delete(sampleLessons[1].id);

      expect(removed, isTrue);
      await expectLater(
        repository.loadAll(),
        completion(equals(<Lesson>[sampleLessons[0], sampleLessons[2]])),
      );
    });

    test(
      'simulateDelayedLessonLoad завершується помилкою StateError при збої',
      () async {
        await expectLater(
          simulateDelayedLessonLoad(
            sampleLessons.first,
            delay: const Duration(milliseconds: 5),
            shouldFail: true,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('Потоки Stream, порядок подій та Isolate', () {
    test('watchAll видає заняття у точному порядку їх додавання', () async {
      await repository.saveAll(sampleLessons);

      await expectLater(
        repository.watchAll(interval: const Duration(milliseconds: 5)),
        emitsInOrder(<Object>[
          sampleLessons[0],
          sampleLessons[1],
          sampleLessons[2],
          emitsDone,
        ]),
      );
    });

    test('генератор watchAll працює ліниво і не стартує до підписки', () async {
      await repository.save(sampleLessons.first);
      var bodyExecuted = false;

      final stream = repository.watchAll(
        interval: const Duration(milliseconds: 5),
        onStarted: () => bodyExecuted = true,
      );

      expect(bodyExecuted, isFalse);
      await expectLater(
        stream,
        emitsInOrder(<Object>[sampleLessons.first, emitsDone]),
      );
      expect(bodyExecuted, isTrue);
    });

    test('watchAll із failAtIndex видає подію, помилку StateError та наступний елемент', () async {
      await repository.saveAll(sampleLessons);

      await expectLater(
        repository.watchAll(
          interval: const Duration(milliseconds: 5),
          failAtIndex: 1,
        ),
        emitsInOrder(<Object>[
          sampleLessons[0],
          emitsError(isA<StateError>()),
          sampleLessons[2],
          emitsDone,
        ]),
      );
    });

    test(
      'конвеєр потоку та буферизація StreamController зберігають порядок подій',
      () async {
        final buffered = await demonstrateBufferedControllerListen(
          sampleLessons,
        );
        expect(
          buffered.map((e) => e.action).toList(),
          equals(<String>['ДОДАНО', 'ОНОВЛЕНО', 'ПЕРЕНЕСЕНО']),
        );

        final source = Stream<ScheduleEvent>.fromIterable(
          sampleLessons.map(
            (lesson) => ScheduleEvent(action: ' ТЕСТ', lesson: lesson),
          ),
        );
        await expectLater(
          buildScheduleEventPipeline(source, minRating: 4.8, takeCount: 2),
          emitsInOrder(<Object>[
            contains(sampleLessons[0].subject),
            contains(sampleLessons[1].subject),
            emitsDone,
          ]),
        );
      },
    );
  });
}
