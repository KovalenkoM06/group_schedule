import 'package:group_schedule/group_schedule.dart';

/// Точка входу консольної програми для лабораторної роботи №1.
void main(List<String> arguments) {
  final counter = makeProcessedCounter();
  final validLessons = <Lesson>[];

  print('--- Перевірка вхідних рядків розкладу ---');
  for (final line in rawScheduleInput) {
    final rowNumber = counter();
    final parsed = parseLineWithDetails(line);
    final lesson = parsed.lesson;

    if (lesson == null) {
      print('Рядок #$rowNumber пропущено (помилка розбору): ${parsed.error}');
    } else {
      final violations = validateLesson(lesson);
      if (violations.isEmpty) {
        validLessons.add(lesson);
      } else {
        print(
          'Рядок #$rowNumber (${lesson.subject}) має порушення діапазонів: '
          '${violations.join(', ')}',
        );
      }
    }
  }

  print('');
  print(buildReport(validLessons));

  // Перевірка фільтра-замикання та маскування номерів аудиторій
  final dartTeacherFilter = makeTeacherFilter('Баличев');
  final dartLessons = sortByStartTime(validLessons.where(dartTeacherFilter));

  print('--- Заняття викладача "Баличев" (з маскуванням аудиторій) ---');
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
