import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class NewMenuPage extends StatefulWidget {
  final ValueChanged<DateTimeRange>? onCreateMenu;

  const NewMenuPage({super.key, this.onCreateMenu});

  @override
  State<NewMenuPage> createState() => _NewMenuPageState();
}

class _NewMenuPageState extends State<NewMenuPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  late DateTime _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _rangeStart = today;
    _rangeEnd = null;
    _focusedDay = today;
  }

  // ---- date helpers ----

  String _formatFullDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    return (days / 7).ceil();
  }

  bool get _isRangeComplete => _rangeEnd != null;

  // ---- day selection ----

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_rangeEnd != null) {
      // Both start and end are set → reset: start = clicked day, clear end
      setState(() {
        _rangeStart = selectedDay;
        _rangeEnd = null;
        _focusedDay = focusedDay;
      });
    } else if (selectedDay.isAfter(_rangeStart)) {
      // Only start is set → set end date
      setState(() {
        _rangeEnd = selectedDay;
        _focusedDay = focusedDay;
      });
    } else {
      // Clicked before or on start → move start
      setState(() {
        _rangeStart = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: const Color(0xFFFFF5EC),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isRangeComplete
                  ? () => widget.onCreateMenu?.call(
                        DateTimeRange(start: _rangeStart, end: _rangeEnd!),
                      )
                  : null,
              icon: const Icon(Icons.restaurant, size: 18),
              label: const Text('创建食谱'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C42),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateInfoCard(theme),
          Expanded(child: _buildCalendar(theme)),
        ],
      ),
    );
  }

  Widget _buildDateInfoCard(ThemeData theme) {
    final label = _isRangeComplete
        ? '${_formatFullDate(_rangeStart)}  ~  ${_formatFullDate(_rangeEnd!)}'
        : _formatFullDate(_rangeStart);
    final subLabel = _isRangeComplete
        ? '${_rangeEnd!.difference(_rangeStart).inDays + 1}天 · 第${_weekNumber(_rangeStart)}周'
        : '请再点击选择结束日期';
    final hint = _isRangeComplete ? '点击日历可重新选择' : '点击日期选择范围';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C42).withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month, color: Color(0xFFFF8C42)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF5D4037).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            hint,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF5D4037).withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: TableCalendar(
            locale: 'zh_CN',
            focusedDay: _focusedDay,
            firstDay: DateTime(2024),
            lastDay: DateTime(2030),
            calendarFormat: _calendarFormat,
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {
              CalendarFormat.month: '月',
              CalendarFormat.week: '周',
            },
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (day) {
              setState(() => _focusedDay = day);
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: const TextStyle(
                color: Color(0xFFFF8C42),
                fontWeight: FontWeight.w600,
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Color(0xFFFF8C42),
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Color(0xFFFF8C42),
              ),
              titleTextStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFFF8C42),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFFFF8C42).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              rangeStartDecoration: const BoxDecoration(
                color: Color(0xFFFF8C42),
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: Color(0xFFFF8C42),
                shape: BoxShape.circle,
              ),
              rangeHighlightColor: const Color(0xFFFFF3E0),
              withinRangeDecoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              weekendTextStyle: const TextStyle(color: Color(0xFFFFAB91)),
              todayTextStyle: const TextStyle(color: Color(0xFF5D4037)),
              selectedTextStyle: const TextStyle(color: Colors.white),
              defaultTextStyle: const TextStyle(color: Color(0xFF5D4037)),
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: const Color(0xFF5D4037).withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
              weekendStyle: TextStyle(
                color: const Color(0xFFFFAB91).withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              dowTextFormatter: (date, locale) {
                const days = ['一', '二', '三', '四', '五', '六', '日'];
                return days[date.weekday - 1];
              },
            ),
          ),
        ),
      ),
    );
  }
}
