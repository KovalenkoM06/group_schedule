/// Функції, перелічення та об'єктна модель розкладу занять групи (варіант 4).
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

/// Тривалість однієї академічної години у хвилинах.
const int academicHourMinutes = 45;

/// Поріг високого рейтингу дисципліни.
const double highRatingThreshold = 4.8;

/// Кількість записів для виведення у звіті за замовчуванням.
const int defaultTopCount = 5;

/// Роздільник стовпців у текстовому звіті за замовчуванням.
const String defaultColumnSeparator = ' | ';

/// Перелічення навчальних днів тижня з полями, константним конструктором і методами.
enum DayOfWeek {
  /// Понеділок.
  monday('Понеділок', 'Пн', 1),

  /// Вівторок.
  tuesday('Вівторок', 'Вт', 2),

  /// Середа.
  wednesday('Середа', 'Ср', 3),

  /// Четвер.
  thursday('Четвер', 'Чт', 4),

  /// П'ятниця.
  friday("П'ятниця", 'Пт', 5),

  /// Субота.
  saturday('Субота', 'Сб', 6, isWeekend: true);

  /// Створює елемент перелічення дня тижня.
  const DayOfWeek(
    this.label,
    this.shortName,
    this.weekdayNumber, {
    this.isWeekend = false,
  });

  /// Повна назва дня тижня українською.
  final String label;

  /// Скорочене позначення дня тижня.
  final String shortName;

  /// Порядковий номер дня у тижні (1..6).
  final int weekdayNumber;

  /// Ознака вихідного або факультативного дня.
  final bool isWeekend;

  /// Перевіряє, чи відповідає рядок [raw] назві або скороченню цього дня.
  bool matchesText(String raw) {
    final normalized = raw.trim().toLowerCase();
    return label.toLowerCase() == normalized ||
        shortName.toLowerCase() == normalized;
  }

  /// Розбирає назву дня тижня з рядка [raw] або повертає `null`.
  static DayOfWeek? tryParse(String raw) =>
      values.where((day) => day.matchesText(raw)).firstOrNull;
}

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

/// Регулярний вираз з іменованими групами для перевірки формату аудиторії (наприклад, І-304 або І-212а).
final RegExp roomRegExp = RegExp(
  r'^(?<building>[А-ЯІЇЄҐA-Z]+)-(?<floor>[1-9])(?<room>\d{2}[а-яіїєґa-z]?)$',
);

/// Методи розширення для рядків із шифром аудиторії.
extension RoomStringExtension on String {
  /// Повертає `true`, якщо рядок відповідає шаблону шифру аудиторії.
  bool get isValidRoomCode => roomRegExp.hasMatch(trim());

  /// Повертає замаскований шифр аудиторії (наприклад, `І-304` -> `І-3**`).
  String maskRoomCode() {
    final match = roomRegExp.firstMatch(trim());
    if (match == null) {
      return this;
    }
    return '${match.namedGroup('building')}-${match.namedGroup('floor')}**';
  }
}

/// Методи розширення для форматування дати та обчислення різниці в днях.
extension ScheduleDateTimeExtension on DateTime {
  /// Форматує дату й час початку заняття у вигляді `YYYY-MM-DD HH:MM`.
  String toScheduleFormat() =>
      '$year-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')} '
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';

  /// Обчислює вік дати у днях відносно [now] або [currentSemesterDate].
  int ageInDays({DateTime? now}) =>
      (now ?? currentSemesterDate).difference(this).inDays;
}

/// Незмінний клас-сутність, що описує одне заняття в розкладі групи.
class Lesson {
  /// Константний генеративний конструктор заняття.
  const Lesson({
    required this.subject,
    required this.teacher,
    required this.type,
    required this.day,
    required this.startTime,
    required this.durationMinutes,
    required this.rating,
    required this.room,
    this._notes,
  }) : assert(durationMinutes > 0, 'Тривалість має бути додатною');

  /// Іменований конструктор із приватним списком ініціалізації для розібраних полів.
  Lesson._fromParts(List<String> parts)
    : subject = parts[0],
      teacher = parts[1],
      type = parts[2],
      day = DayOfWeek.tryParse(parts[3]) ?? DayOfWeek.monday,
      startTime = DateTime.tryParse(parts[4]) ?? currentSemesterDate,
      durationMinutes = int.tryParse(parts[5]) ?? minDurationMinutes,
      rating = double.tryParse(parts[6]) ?? minCourseRating,
      room = parts[7],
      _notes = null;

  /// Іменований конструктор `fromCsv`, який створює екземпляр із CSV-рядка [line].
  ///
  /// Кидає [FormatException], якщо рядок не відповідає очікуваному формату.
  Lesson.fromCsv(String line) : this._fromParts(_extractValidCsvParts(line));

  /// Фабричний конструктор із кешуванням розібраних екземплярів у статичному полі [_cache].
  factory Lesson.cached(String line) {
    final key = line.trim();
    return _cache.putIfAbsent(key, () => Lesson.fromCsv(key));
  }

  /// Фабричний конструктор, який повертає розібраний об'єкт або [defaultLesson] у разі помилки.
  factory Lesson.fromCsvOrDefault(String line) =>
      tryParseCsv(line).lesson ?? defaultLesson;

  /// Кеш створених занять за вхідним CSV-рядком.
  static final Map<String, Lesson> _cache = <String, Lesson>{};

  /// Значення заняття за замовчуванням для пошкоджених рядків.
  static final Lesson defaultLesson = Lesson(
    subject: 'Самостійна робота',
    teacher: 'Черговий викладач',
    type: 'Консультація',
    day: DayOfWeek.friday,
    startTime: currentSemesterDate,
    durationMinutes: 60,
    rating: 4.0,
    room: 'І-101',
    notes: 'Створено за замовчуванням',
  );

  /// Назва навчальної дисципліни.
  final String subject;

  /// Прізвище та ініціали викладача.
  final String teacher;

  /// Вид заняття (Лекція, Лабораторна, Практична, Консультація).
  final String type;

  /// День тижня як елемент перелічення [DayOfWeek].
  final DayOfWeek day;

  /// Дата й час початку заняття.
  final DateTime startTime;

  /// Тривалість заняття у хвилинах.
  final int durationMinutes;

  /// Рейтинг (оцінка) курсу.
  final double rating;

  /// Шифр аудиторії.
  final String room;

  /// Приватне поле примітки (демонструє промоцію типів приватного `final`-поля).
  final String? _notes;

  /// Кількість збережених об'єктів у кеші фабричного конструктора.
  static int get cacheSize => _cache.length;

  /// Очищує кеш фабричного конструктора.
  static void clearCache() => _cache.clear();

  /// Гетер рядкової назви дня тижня для сумісності зі звітом.
  String get dayOfWeek => day.label;

  /// Обчислюваний гетер часу завершення заняття.
  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  /// Обчислюваний гетер кількості академічних годин (по 45 хв).
  double get academicHours => durationMinutes / academicHourMinutes;

  /// Обчислюваний гетер ознаки високорейтингового курсу.
  bool get isHighRated => rating >= highRatingThreshold;

  /// Публічний гетер над приватним полем [_notes].
  String? get notes => _notes;

  /// Повертає форматований опис примітки (приватне `final`-поле [_notes] промотується до `String`).
  String formatNotes() {
    if (_notes != null) {
      return 'Примітка (${_notes.length} симв.): $_notes';
    }
    return 'Без додаткових приміток';
  }

  /// Допоміжний метод перевірки та розбиття CSV-рядка для конструктора `fromCsv`.
  static List<String> _extractValidCsvParts(String line) {
    final parsed = tryParseCsv(line);
    if (parsed.lesson == null) {
      throw FormatException(parsed.error ?? 'Некоректний CSV-рядок', line);
    }
    return line.trim().split(fieldSeparator).map((e) => e.trim()).toList();
  }

  /// Безпечно розбирає CSV-рядок [line] без винятків, повертаючи [ParseResult].
  static ParseResult tryParseCsv(String line) {
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
    final rawDay = parts[3];
    final rawDate = parts[4];
    final rawDuration = parts[5];
    final rawRating = parts[6];
    final room = parts[7];

    if (subject.isEmpty ||
        teacher.isEmpty ||
        type.isEmpty ||
        rawDay.isEmpty ||
        room.isEmpty) {
      return (lesson: null, error: 'Одне з текстових полів порожнє');
    }

    final day = DayOfWeek.tryParse(rawDay);
    if (day == null) {
      return (lesson: null, error: 'Невідомий день тижня: "$rawDay"');
    }

    final startTime = DateTime.tryParse(rawDate);
    if (startTime == null) {
      return (lesson: null, error: 'Некоректна дата початку: "$rawDate"');
    }

    final durationMinutes = int.tryParse(rawDuration);
    if (durationMinutes == null || durationMinutes <= 0) {
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
      lesson: Lesson(
        subject: subject,
        teacher: teacher,
        type: type,
        day: day,
        startTime: startTime,
        durationMinutes: durationMinutes,
        rating: rating,
        room: room,
      ),
      error: null,
    );
  }

  @override
  String toString() =>
      'Lesson($subject, $type, ${day.shortName}, '
      '${startTime.toScheduleFormat()}..${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}, '
      '$teacher, ауд. $room, $durationMinutes хв, рейтинг $rating)';
}

/// Результат розбору одного рядка (або розібране заняття, або текст помилки).
typedef ParseResult = ({Lesson? lesson, String? error});

/// Константний список вхідних рядків розкладу у CSV-подібному форматі (18 записів).
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
  'Системне програмування;Кравчук Н. В.;Практична;Середа;некоректна_дата;90;4.3;Г-105',
];

/// Розбирає один рядок [line] у [ParseResult] з описом помилки, якщо рядок пошкоджений.
ParseResult parseLineWithDetails(String line) => Lesson.tryParseCsv(line);

/// Розбирає рядок [line] в об'єкт [Lesson] або повертає `null`, якщо формат некоректний.
Lesson? parseLine(String line) => Lesson.tryParseCsv(line).lesson;

/// Перевіряє діапазони значень об'єкта [lesson] і повертає список знайдених порушень.
List<String> validateLesson(Lesson lesson) {
  final year = lesson.startTime.year;

  return <String>[
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
    if (!isValidRoom(lesson.room))
      'Неправильний формат аудиторії "${lesson.room}"',
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

/// Замикання-лічильник оброблених записів, яке захоплює локальну змінну `count`.
int Function() makeProcessedCounter([int start = 0]) {
  var count = start;
  return () {
    count++;
    return count;
  };
}

/// Замикання (фабрика предикатів), що захоплює підрядок прізвища [teacherPart] для фільтрації.
bool Function(Lesson) makeTeacherFilter(String teacherPart) {
  final query = teacherPart.trim().toLowerCase();
  return (lesson) => lesson.teacher.toLowerCase().contains(query);
}

/// Перевіряє формат аудиторії [room] регулярним виразом.
bool isValidRoom(String room) => room.isValidRoomCode;

/// Маскує номер кабінету в шифрі аудиторії [room] (наприклад, `І-304` -> `І-3**`).
String maskRoomNumber(String room) => room.maskRoomCode();

/// Обчислює вік запису [lesson] у днях відносно [now] через `DateTime.difference` і `Duration`.
int calculateAgeInDays(Lesson lesson, {DateTime? now}) =>
    lesson.startTime.ageInDays(now: now);

/// Формує текстовий звіт за списком занять [items] за допомогою [StringBuffer].
String buildReport(
  List<Lesson> items, {
  int topCount = defaultTopCount,
  bool ascending = false,
  String separator = defaultColumnSeparator,
  bool maskRooms = false,
  DateTime? now,
}) {
  final buffer = StringBuffer()
    ..writeln('=== ЗВІТ ПО РОЗКЛАДУ ЗАНЯТЬ ГРУПИ (Варіант 4) ===');

  if (items.isEmpty) {
    buffer.writeln('Немає коректних записів для побудови звіту.');
    return buffer.toString();
  }

  final totalMinutes = calculateTotalMinutes(items);
  final avgRating = calculateAverageRating(items);
  final minMax = findMinMaxDuration(items);

  buffer
    ..writeln('Усього коректних занять: ${items.length}')
    ..writeln('Сумарна тривалість: $totalMinutes хв')
    ..writeln('Середній рейтинг дисциплін: ${avgRating.toStringAsFixed(2)}');

  if (minMax != null) {
    buffer.writeln(
      'Тривалість занять: мін = ${minMax.min} хв, макс = ${minMax.max} хв',
    );
  }

  buffer
    ..writeln()
    ..writeln('Топ-$topCount занять (ascending: $ascending):');

  final sorted = sortByRatingAndDuration(items, ascending: ascending);
  for (final lesson in sorted.take(topCount)) {
    final roomText = maskRooms ? maskRoomNumber(lesson.room) : lesson.room;
    final ageDays = calculateAgeInDays(lesson, now: now);
    final dateStr = lesson.startTime.toScheduleFormat();

    final line = <String>[
      lesson.dayOfWeek,
      dateStr,
      lesson.subject,
      lesson.type,
      lesson.teacher,
      '${lesson.durationMinutes} хв (${lesson.academicHours.toStringAsFixed(1)} акад. год)',
      'оцінка ${lesson.rating}',
      'ауд. $roomText',
      'вік: $ageDays дн.',
    ].join(separator);

    buffer.writeln('  $line');
  }

  buffer
    ..writeln()
    ..writeln('Групування за днями тижня:');

  final grouped = groupByDay(items);
  for (final day in DayOfWeek.values) {
    final dayLessons = grouped[day.label];
    if (dayLessons != null) {
      final dayMinutes = calculateTotalMinutes(dayLessons);
      final dayAvg = calculateAverageRating(dayLessons);
      buffer.writeln(
        '  - ${day.label} (${day.shortName}): ${dayLessons.length} занять, '
        'сумарно $dayMinutes хв, середній бал ${dayAvg.toStringAsFixed(2)}',
      );
    }
  }

  return buffer.toString();
}
