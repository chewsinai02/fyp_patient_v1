import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class DailyTasksPage extends StatefulWidget {
  final int patientId;
  final String patientName;
  final bool isPersonalTask;

  const DailyTasksPage({
    super.key,
    required this.patientId,
    required this.patientName,
    this.isPersonalTask = false,
  });

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final DateTime _firstDay = DateTime(2024, 1, 1);
  final DateTime _lastDay = DateTime(2025, 12, 31);
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _isLegendVisible = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    // Initialize with current date or first day if out of range
    final now = DateTime.now();
    final currentDate = DateTime(now.year, now.month, now.day);

    // Ensure the focused day is within the valid range
    if (currentDate.isAfter(_lastDay)) {
      _focusedDay = _lastDay;
    } else if (currentDate.isBefore(_firstDay)) {
      _focusedDay = _firstDay;
    } else {
      _focusedDay = currentDate;
    }
    _selectedDay = _focusedDay;

    // Initialize timezone and notifications
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    // Create separate channels for personal and family tasks
    const personalChannel = AndroidNotificationChannel(
      'personal_tasks',
      'Personal Tasks',
      description: 'Notifications for your personal tasks',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const familyChannel = AndroidNotificationChannel(
      'family_tasks',
      'Family Tasks',
      description: 'Notifications for family member tasks',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(personalChannel);
    await androidImplementation?.createNotificationChannel(familyChannel);

    const androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitializationSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        final payload = response.payload;
        if (payload != null) {
          final parts = payload.split('_');
          if (parts.length == 2) {
            final patientId = int.parse(parts[0]);
            final taskId = int.parse(parts[1]);
            print('Notification tapped - Patient: $patientId, Task: $taskId');
          }
        }
      },
    );
  }

  Future<void> _scheduleTaskNotification(Map<String, dynamic> task) async {
    print('\n=== SCHEDULING TASK NOTIFICATION ===');
    print('Task ID: ${task['id']}');
    print('Title: ${task['title']}');
    print('Status: ${task['status']}');
    print('Due Date: ${task['due_date']}');

    final status = task['status'] as String;
    if (status != 'pending') {
      print('Skipping notification - task is not pending');
      return;
    }

    final DateTime dueDate = task['due_date'] as DateTime;
    final now = DateTime.now();

    // Don't schedule if already passed
    if (dueDate.isBefore(now)) return;

    final taskId = task['id'] as int;
    final title = task['title'] as String;
    final priority = task['priority'] as String;

    // Calculate time until due
    final timeUntilDue = dueDate.difference(now);

    // Schedule notification 30 minutes before due time
    if (timeUntilDue.inMinutes > 30) {
      final warningTime = dueDate.subtract(const Duration(minutes: 30));

      try {
        // Create notification details
        final androidDetails = AndroidNotificationDetails(
          widget.isPersonalTask ? 'personal_tasks' : 'family_tasks',
          widget.isPersonalTask ? 'Personal Tasks' : 'Family Tasks',
          channelDescription: widget.isPersonalTask
              ? 'Notifications for your personal tasks'
              : 'Notifications for family member tasks',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
          enableVibration: true,
          playSound: true,
          color: Colors.red,
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );

        // Create urgent notification message
        final notificationTitle = widget.isPersonalTask
            ? '⚠️ Task Due Soon: $title'
            : '⚠️ ${widget.patientName}\'s Task Due Soon: $title';

        final notificationBody = widget.isPersonalTask
            ? 'URGENT: Task will pass in 30 minutes!\nPriority: ${priority.toUpperCase()}'
            : 'URGENT: Family member task will pass in 30 minutes!\nPriority: ${priority.toUpperCase()}';

        // Schedule the notification
        await flutterLocalNotificationsPlugin.zonedSchedule(
          taskId,
          notificationTitle,
          notificationBody,
          tz.TZDateTime.from(warningTime, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: '${widget.patientId}_$taskId',
        );

        print('Warning notification scheduled for task: $title');
        print('Due date: $dueDate');
        print('Warning time: $warningTime');
        print('For: ${widget.patientName}');
      } catch (e) {
        print('Error scheduling warning notification: $e');
      }
    }

    // If task is very close to passing (less than 30 minutes), show immediate notification
    if (timeUntilDue.inMinutes <= 30 && timeUntilDue.inMinutes > 0) {
      try {
        await flutterLocalNotificationsPlugin.show(
          taskId,
          widget.isPersonalTask
              ? '🚨 URGENT: Task Almost Due!'
              : '🚨 URGENT: Family Task Almost Due!',
          'Task "$title" will pass in ${timeUntilDue.inMinutes} minutes!\nPriority: ${priority.toUpperCase()}',
          NotificationDetails(
            android: AndroidNotificationDetails(
              widget.isPersonalTask ? 'personal_tasks' : 'family_tasks',
              widget.isPersonalTask ? 'Personal Tasks' : 'Family Tasks',
              channelDescription: 'Urgent task notifications',
              importance: Importance.max,
              priority: Priority.max,
              enableVibration: true,
              playSound: true,
              color: Colors.red,
              fullScreenIntent: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: '${widget.patientId}_$taskId',
        );
        print('Immediate warning sent for nearly passing task: $title');
      } catch (e) {
        print('Error showing immediate warning: $e');
      }
    }
  }

  Future<void> _cancelTaskNotification(int taskId) async {
    await flutterLocalNotificationsPlugin.cancel(taskId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 19, 15, 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple,
                    Colors.deepPurple.shade300,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Daily Tasks',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.patientName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_calendarFormat == CalendarFormat.week) {
                                _calendarFormat = CalendarFormat.month;
                              } else {
                                _calendarFormat = CalendarFormat.week;
                              }
                            });
                          },
                          icon: Icon(
                            _calendarFormat == CalendarFormat.week
                                ? Icons.calendar_view_month
                                : Icons.calendar_view_week,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Calendar and Tasks Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TableCalendar<dynamic>(
                    firstDay: _firstDay,
                    lastDay: _lastDay,
                    focusedDay: _focusedDay,
                    currentDay: DateTime.now(),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = selectedDay;
                        });
                      }
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        shape: BoxShape.circle,
                      ),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Legend',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          _isLegendVisible
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _isLegendVisible = !_isLegendVisible;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status:',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildLegendItem(
                                Icons.check_circle,
                                'Completed',
                                Colors.green,
                              ),
                              _buildLegendItem(
                                Icons.access_time,
                                'Pending',
                                Colors.orange,
                              ),
                              _buildLegendItem(
                                Icons.warning,
                                'Passed',
                                Colors.red,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Priority:',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildLegendItem(
                                Icons.priority_high,
                                'Urgent',
                                Colors.red,
                              ),
                              _buildLegendItem(
                                Icons.arrow_upward,
                                'High',
                                Colors.orange,
                              ),
                              _buildLegendItem(
                                Icons.remove,
                                'Medium',
                                Colors.yellow[700]!,
                              ),
                              _buildLegendItem(
                                Icons.arrow_downward,
                                'Low',
                                Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondChild: const SizedBox.shrink(),
                  crossFadeState: _isLegendVisible
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                ),
                _buildTasksList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return SizedBox(
      height:
          MediaQuery.of(context).size.height - (_isLegendVisible ? 450 : 350),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseService.instance.getTasksByDate(
          widget.patientId,
          selectedDate: _selectedDay,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final tasks = snapshot.data ?? [];

          // Schedule notifications for pending tasks
          for (final task in tasks) {
            if (task['status'] == 'pending') {
              _scheduleTaskNotification(task);
            }
          }

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks for ${DateFormat('MMM d').format(_selectedDay)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tasks.length,
            itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final dueDateTime = task['due_date'] as DateTime;
    final timeString = DateFormat('h:mm a').format(dueDateTime);
    final status = task['status'] as String;
    final priority = task['priority'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                ),
                const SizedBox(width: 4),
                Icon(
                  _getPriorityIcon(priority),
                  color: _getPriorityColor(priority),
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: task['status'] == 'completed'
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (task['description']?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    task['description'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onTap: () async {
                // Toggle task status
                String newStatus;
                if (status == 'pending') {
                  newStatus = 'completed';
                  // Cancel notification when task is completed
                  await _cancelTaskNotification(task['id'] as int);
                  print(
                      'Cancelled notification for completed task: ${task['id']}');
                } else if (status == 'completed') {
                  newStatus = 'pending';
                  // Schedule new notification when task is marked as pending
                  await _scheduleTaskNotification(task);
                  print(
                      'Scheduled notification for pending task: ${task['id']}');
                } else {
                  return;
                }

                // Update task status in database
                await DatabaseService.instance.updateTaskStatus(
                  task['id'] as int,
                  newStatus,
                );

                // Refresh the tasks list
                setState(() {});
              },
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'passed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'passed':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.priority_high;
      case 'high':
        return Icons.arrow_upward;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
