/// Функції та структури даних для обробки розкладу занять групи (ЛР 1, варіант 4).
library;

/// Роздільник полів у вхідних рядках розкладу.
const String fieldSeparator = ';';

/// Кількість полів в одному записі розкладу.
const int expectedFieldsCount = 8;

/// Мінімальний допустимий рік для заняття.
const int minAllowedYear = 2024;

/// Максимальний допустимий рік для заняття.
const int maxAllowedYear = 2030;

/// Мінімальна тривалість заняття у хвилинах.
const int minDurationMinutes = 45;

/// Максимальна тривалість заняття у хвилинах.
const int maxDurationMinutes = 240;

/// Мінімальна оцінка (рейтинг) складності/важливості курсу.
const double minCourseRating = 1.0;

/// Максимальна оцінка (рейтинг) курсу.
const double maxCourseRating = 5.0;

/// Кількість записів для виведення у звіті за замовчуванням.
const int defaultTopCount = 5;

/// Роздільник стовпців у текстовому звіті за замовчуванням.
const String defaultColumnSeparator = ' | ';

/// Список навчальних днів тижня.
const List<String> allowedDays = <String>[
  'Понеділок',
  'Вівторок',
  'Середа',
  'Четвер',
  "П'ятниця",
  'Субота',
];

/// Допустимі типи занять.
const Set<String> allowedLessonTypes = <String>{
  'Лекція',
  'Лабораторна',
  'Практична',
  'Консультація',
};

/// Опорна дата для підрахунку віку записів у днях.
final DateTime currentSemesterDate = DateTime(2026, 10, 27);

/// Запис (Record), що описує одне заняття в розкладі групи.
///
/// Містить основні поля за варіантом 4 (дисципліна, викладач, тип, день тижня,
/// час початку, аудиторія) та числові поля тривалості й рейтингу для перевірки діапазонів.
typedef Lesson = ({
  String subject,
  String teacher,
  String type,
  String dayOfWeek,
  DateTime startTime,
  int durationMinutes,
  double rating,
  String room,
});

/// Результат розбору одного рядка (або розібране заняття, або текст помилки).
typedef ParseResult = ({Lesson? lesson, String? error});

/// Константний список вхідних рядків розкладу у CSV-подібному форматі (18 записів).
///
/// Формат: `дисципліна;викладач;тип;день_тижня;час_початку;тривалість_хв;оцінка;аудиторія`.
/// Серед записів є 3 навмисно пошкоджені рядки (№16–18) та 1 запис із виходом за межі діапазонів (№15).
const List<String> rawScheduleInput = <String>[
  'Програмування мовою Dart;Баличев М. Д.;Лекція;Понеділок;2026-10-19T08:30:00;90;4.9;І-304',
  'Програмування мовою Dart;Баличев М. Д.;Лабораторна;Понеділок;2026-10-19T10:15:00;180;5.0;І-212а',
  'Архітектура ПЗ;Смеляков К. С.;Лекція;Понеділок;2026-10-19T13:45:00;90;4.7;Г-401',
  'Організація баз даних;Лановий О. Ф.;Лекція;Вівторок;2026-10-20T08:30:00;90;4.8;З-205',
  'Організація баз даних;Лановий О. Ф.;Лабораторна;Вівторок;2026-10-20T10:15:00;90;4.8;І-108',
  'Компʼютерні мережі;Коваленко А. І.;Лекція;Вівторок;2026-10-20T12:00:00;90;4.5;Г-315',
  'Архітектура ПЗ;Смеляков К. С.;Практична;Середа;2026-10-21T08:30:00;90;4.6;Г-402',
  'Безпека програмних систем;Ткаченко В. П.;Лекція;Середа;2026-10-21T10:15:00;90;4.7;І-310',
  'Безпека програмних систем;Ткаченко В. П.;Лабораторна;Середа;2026-10-21T12:00:00;180;4.9;І-214б',
  'Програмування мовою Dart;Баличев М. Д.;Практична;Четвер;2026-10-22T08:30:00;90;5.0;І-304',
  'Методи оптимізації;Романенко С. В.;Лекція;Четвер;2026-10-22T10:15:00;90;4.2;З-410',
  'Компʼютерні мережі;Коваленко А. І.;Лабораторна;Четвер;2026-10-22T12:00:00;90;4.4;Г-209',
  'Тестування ПЗ;Мельник О. Г.;Лекція;П\'ятниця;2026-10-23T08:30:00;90;4.6;І-405',
  'Програмування мовою Dart;Баличев М. Д.;Консультація;П\'ятниця;2026-10-23T12:00:00;60;4.9;І-101',

  // Запис із порушенням діапазонів (рік 2018, тривалість 350 хв, оцінка 9.5)
  'Застарілий курс;Іванов І. І.;Лекція;Субота;2018-05-10T10:00:00;350;9.5;АУД_БЕЗ_ФОРМАТУ',

  // 3 навмисно пошкоджені записи:
  // 1) Відсутні поля
  'Неповний запис;Петренко П. П.;Лекція;Понеділок',
  // 2) Нечислове значення у числовому полі тривалості
  'Алгоритми і структури даних;Сидоренко О. М.;Лабораторна;Вівторок;2026-10-20T13:45:00;девʼяносто;4.5;І-201',
  // 3) Некоректна дата
  'Системне програмування;Кравчук Н. В.;Практична;Середа;2026-99-99T99:00;90;4.3;Г-105',
];

/// Розбирає один рядок [line] у [ParseResult] з описом помилки, якщо рядок пошкоджений.
///
/// Використовує `split`, `DateTime.tryParse`, `int.tryParse` та `double.tryParse`
/// без використання блоків `try/catch`.
ParseResult parseLineWithDetails(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) {
    return (lesson: null, error: 'Порожній рядок');
  }

  final parts = trimmed.split(fieldSeparator).map((e) => e.trim()).toList();
  if (parts.length != expectedFieldsCount) {
    return (
      lesson: null,
      error:
          'Неправильна кількість полів: очікувалось $expectedFieldsCount, '
          'а отримано ${parts.length}',
    );
  }

  final subject = parts[0];
  final teacher = parts[1];
  final type = parts[2];
  final dayOfWeek = parts[3];
  final rawDate = parts[4];
  final rawDuration = parts[5];
  final rawRating = parts[6];
  final room = parts[7];

  if (subject.isEmpty ||
      teacher.isEmpty ||
      type.isEmpty ||
      dayOfWeek.isEmpty ||
      room.isEmpty) {
    return (lesson: null, error: 'Одне з текстових полів порожнє');
  }

  final startTime = DateTime.tryParse(rawDate);
  if (startTime == null) {
    return (lesson: null, error: 'Некоректна дата початку: "$rawDate"');
  }

  final durationMinutes = int.tryParse(rawDuration);
  if (durationMinutes == null) {
    return (
      lesson: null,
      error: 'Нечислове значення тривалості: "$rawDuration"',
    );
  }

  final rating = double.tryParse(rawRating);
  if (rating == null) {
    return (lesson: null, error: 'Нечислове значення оцінки: "$rawRating"');
  }

  return (
    lesson: (
      subject: subject,
      teacher: teacher,
      type: type,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      durationMinutes: durationMinutes,
      rating: rating,
      room: room,
    ),
    error: null,
  );
}

/// Розбирає рядок [line] у запис [Lesson] або повертає `null`, якщо формат некоректний.
Lesson? parseLine(String line) => parseLineWithDetails(line).lesson;

/// Перевіряє діапазони значень запису [lesson] (рік, тривалість, оцінка, день, тип)
/// і повертає список знайдених порушень.
List<String> validateLesson(Lesson lesson) {
  final year = lesson.startTime.year;

  return <String>[
    if (!allowedDays.contains(lesson.dayOfWeek))
      'Невідомий день тижня "${lesson.dayOfWeek}"',
    if (!allowedLessonTypes.contains(lesson.type))
      'Невідомий тип заняття "${lesson.type}"',
    if (year < minAllowedYear || year > maxAllowedYear)
      'Рік ($year) виходить за межі $minAllowedYear..$maxAllowedYear',
    if (lesson.durationMinutes < minDurationMinutes ||
        lesson.durationMinutes > maxDurationMinutes)
      'Тривалість (${lesson.durationMinutes} хв) поза межами '
          '$minDurationMinutes..$maxDurationMinutes хв',
    if (lesson.rating < minCourseRating || lesson.rating > maxCourseRating)
      'Оцінка (${lesson.rating}) поза межами $minCourseRating..$maxCourseRating',
  ];
}

/// Відбирає лише коректні записи зі списку рядків [lines] через конвеєр і tear-off `parseLine`.
List<Lesson> parseValidLessons(Iterable<String> lines) => lines
    .map(parseLine)
    .whereType<Lesson>()
    .where((lesson) => validateLesson(lesson).isEmpty)
    .toList();

/// Конвеєр 1 (Сума): рахує загальну тривалість занять у хвилинах через `where -> map -> fold`.
int calculateTotalMinutes(Iterable<Lesson> lessons, {String? type}) => lessons
    .where((lesson) => type == null || lesson.type == type)
    .map((lesson) => lesson.durationMinutes)
    .fold<int>(0, (sum, minutes) => sum + minutes);

/// Конвеєр 2 (Середнє): обчислює середній рейтинг занять через `where -> map -> fold`.
double calculateAverageRating(Iterable<Lesson> lessons, {String? dayOfWeek}) {
  final result = lessons
      .where((lesson) => dayOfWeek == null || lesson.dayOfWeek == dayOfWeek)
      .map((lesson) => lesson.rating)
      .fold<({double sum, int count})>((
        sum: 0.0,
        count: 0,
      ), (acc, rating) => (sum: acc.sum + rating, count: acc.count + 1));
  return result.count == 0 ? 0.0 : result.sum / result.count;
}

/// Конвеєр 3 (Мінімум/максимум): знаходить мінімальну і максимальну тривалість заняття.
({int min, int max})? findMinMaxDuration(
  Iterable<Lesson> lessons, {
  String? teacher,
}) => lessons
    .where((lesson) => teacher == null || lesson.teacher == teacher)
    .map((lesson) => lesson.durationMinutes)
    .fold<({int min, int max})?>(
      null,
      (acc, duration) => acc == null
          ? (min: duration, max: duration)
          : (
              min: duration < acc.min ? duration : acc.min,
              max: duration > acc.max ? duration : acc.max,
            ),
    );

/// Шукає перше заняття за назвою дисципліни [subject] через `firstOrNull`.
Lesson? findFirstBySubject(Iterable<Lesson> lessons, String subject) =>
    lessons.where((lesson) => lesson.subject == subject).firstOrNull;

/// Групує заняття у `Map<String, List<Lesson>>` за днем тижня.
Map<String, List<Lesson>> groupByDay(Iterable<Lesson> lessons) {
  final grouped = <String, List<Lesson>>{};
  for (final lesson in lessons) {
    grouped.putIfAbsent(lesson.dayOfWeek, () => <Lesson>[]).add(lesson);
  }
  return grouped;
}

/// Сортує заняття за часом початку (перший критерій) з перемиканням напряму [ascending].
List<Lesson> sortByStartTime(
  Iterable<Lesson> lessons, {
  bool ascending = true,
}) {
  final list = lessons.toList()
    ..sort((a, b) {
      final cmp = a.startTime.compareTo(b.startTime);
      return ascending ? cmp : -cmp;
    });
  return list;
}

/// Сортує заняття за оцінкою та тривалістю (другий критерій) з параметром [ascending].
List<Lesson> sortByRatingAndDuration(
  Iterable<Lesson> lessons, {
  bool ascending = false,
}) {
  final list = lessons.toList()
    ..sort((a, b) {
      var cmp = a.rating.compareTo(b.rating);
      if (cmp == 0) {
        cmp = a.durationMinutes.compareTo(b.durationMinutes);
      }
      return ascending ? cmp : -cmp;
    });
  return list;
}
