import 'package:logger/logger.dart';

final barruuLogger = Logger(
  printer: PrettyPrinter(
    lineLength: 80,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
