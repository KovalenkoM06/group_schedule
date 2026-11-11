import 'package:group_schedule/group_schedule.dart';

/// Точка входу консольної програми для лабораторної роботи №2.
void main(List<String> arguments) {
  final counter = makeProcessedCounter();
  final repository = Repository<Lesson>();

  print('--- Перевірка вхідних рядків розкладу та наповнення сховища ---');
  for (final line in rawScheduleInput) {
    final rowNumber = counter();
    // Деструктуризація запису ParseResult під час розбору
    final (:lesson, :error) = parseLineWithDetails(line);

    if (lesson == null) {
      print('Рядок #$rowNumber пропущено (помилка розбору): $error');
    } else {
      final violations = validateLesson(lesson);
      if (violations.isEmpty) {
        repository.add(Lesson.cached(line));
      } else {
        print(
          'Рядок #$rowNumber (${lesson.subject}) має порушення діапазонів: '
          '${violations.join(', ')}',
        );
      }
    }
  }

  print('');
  print('--- Перевірка рівності обʼєктів (==, hashCode) та кешу ---');
  final firstCsv = rawScheduleInput.first;
  final copyA = Lesson.fromCsv(firstCsv);
  final copyB = Lesson.fromCsv(firstCsv);
  final uniqueSet = <Lesson>{copyA, copyB};
  print(
    'Два окремі екземпляри Lesson.fromCsv: '
    'identical = ${identical(copyA, copyB)}, '
    'copyA == copyB = ${copyA == copyB}, '
    'розмір Set = ${uniqueSet.length}',
  );
  print(
    'Кешовані екземпляри Lesson.cached: '
    'identical = ${identical(Lesson.cached(firstCsv), Lesson.cached(firstCsv))}, '
    'усього в кеші: ${Lesson.cacheSize}',
  );

  final fallback = Lesson.fromCsvOrDefault('пошкоджений_рядок');
  print(
    'Заняття за замовчуванням: ${fallback.subject} (${fallback.formatNotes()})',
  );

  print('');
  print(
    '--- Поліморфізм, sealed-ієрархія, домішка та зіставлення зі зразком ---',
  );
  for (final lesson in repository.all.take(4)) {
    final activity = lesson.activity;
    final weight = activityWeight(activity);
    final loadType = classifyLessonLoad(lesson);
    print(
      '  • ${lesson.subject} [${activity.describeActivity()}, вага: $weight, '
      'самостійна: ${lesson.recommendedSelfStudyMinutes} хв] -> $loadType',
    );
  }

  final exam = ExamSession(
    title: 'Підсумковий залік з Програмування мовою Dart',
    organizer: 'Баличев М. Д.',
    examDate: DateTime(2026, 12, 24, 10, 0),
    room: 'І-304',
  );
  print('  • Подія з іншої гілки ієрархії (домішка): $exam');

  print('');
  print(buildReport(repository.all));

  // Перевірка пошуку у сховищі та маскування аудиторій
  final dartTeacherFilter = makeTeacherFilter('Баличев');
  final dartLessons = sortByStartTime(repository.where(dartTeacherFilter));

  print(
    '--- Заняття викладача "Баличев" зі сховища (з маскуванням аудиторій) ---',
  );
  print(
    buildReport(
      dartLessons,
      topCount: 3,
      ascending: true,
      separator: ' ; ',
      maskRooms: true,
    ),
  );
}
