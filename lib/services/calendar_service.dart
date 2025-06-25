import 'package:device_calendar/device_calendar.dart' as device_cal;
import 'package:add_2_calendar/add_2_calendar.dart' as add2cal;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';

class CalendarService {
  static device_cal.DeviceCalendarPlugin? _deviceCalendarPlugin;
  static List<device_cal.Calendar>? _calendars;

  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    
    _deviceCalendarPlugin = device_cal.DeviceCalendarPlugin();
    
    // Request calendar permission
    var permissionStatus = await Permission.calendar.request();
    
    if (permissionStatus.isGranted) {
      try {
        final calendarsResult = await _deviceCalendarPlugin!.retrieveCalendars();
        if (calendarsResult.isSuccess && calendarsResult.data != null) {
          _calendars = calendarsResult.data!
              .where((cal) => !(cal.isReadOnly ?? true) && cal.name != null)
              .toList();
        }
      } catch (e) {
        print('Calendar initialization error: $e');
      }
    }
  }

  static Future<String?> addEventToCalendar(Task task) async {
    if (_deviceCalendarPlugin == null || _calendars == null || _calendars!.isEmpty) {
      return null;
    }

    try {
      final calendar = _calendars!.first;
      final event = device_cal.Event(
        calendar.id,
        title: task.title,
        description: task.description,
        start: tz.TZDateTime.from(task.dueDate, tz.local),
        end: tz.TZDateTime.from(
          task.dueDate.add(Duration(minutes: task.durationMinutes)),
          tz.local,
        ),
      );

      final result = await _deviceCalendarPlugin!.createOrUpdateEvent(event);
      if (result?.isSuccess == true) {
        return result!.data;
      }
    } catch (e) {
      print('Error adding event to calendar: $e');
    }
    return null;
  }

  static Future<void> addToSystemCalendar(Task task) async {
    try {
      final add2cal.Event event = add2cal.Event(
        title: task.title,
        description: task.description ?? '',
        location: '',
        startDate: task.dueDate,
        endDate: task.dueDate.add(Duration(minutes: task.durationMinutes)),
        iosParams: const add2cal.IOSParams(),
        androidParams: const add2cal.AndroidParams(),
      );

      await add2cal.Add2Calendar.addEvent2Cal(event);
    } catch (e) {
      print('Error adding to system calendar: $e');
    }
  }

  static Future<void> removeEventFromCalendar(String eventId) async {
    if (_deviceCalendarPlugin == null) return;

    try {
      await _deviceCalendarPlugin!.deleteEvent(null, eventId);
    } catch (e) {
      print('Error removing event from calendar: $e');
    }
  }
}
