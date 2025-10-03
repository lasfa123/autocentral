// lib/widgets/modern_calendar_picker.dart
import 'package:flutter/material.dart';

class ModernCalendarPicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime) onDateSelected;
  final String title;

  const ModernCalendarPicker({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    required this.onDateSelected,
    this.title = 'Sélectionner une date',
  });

  @override
  State<ModernCalendarPicker> createState() => _ModernCalendarPickerState();
}

class _ModernCalendarPickerState extends State<ModernCalendarPicker> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.indigo[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Month navigation
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      Text(
                        _formatMonthYear(_currentMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Calendar grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildCalendar(),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!, width: 2),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onDateSelected(_selectedDate);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirmer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        // Day headers
        Row(
          children: ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
              .map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ))
              .toList(),
        ),

        const SizedBox(height: 16),

        // Calendar grid
        Expanded(
          child: _buildCalendarGrid(),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7;

    final days = <Widget>[];

    // Previous month days
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month, 0);
    for (int i = firstDayWeekday - 1; i >= 0; i--) {
      final day = prevMonth.day - i;
      days.add(_buildDayCell(
        day,
        DateTime(_currentMonth.year, _currentMonth.month - 1, day),
        isCurrentMonth: false,
      ));
    }

    // Current month days
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(_buildDayCell(
        day,
        DateTime(_currentMonth.year, _currentMonth.month, day),
        isCurrentMonth: true,
      ));
    }

    // Next month days
    final remainingCells = 42 - days.length;
    for (int day = 1; day <= remainingCells; day++) {
      days.add(_buildDayCell(
        day,
        DateTime(_currentMonth.year, _currentMonth.month + 1, day),
        isCurrentMonth: false,
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: days,
    );
  }

  Widget _buildDayCell(int day, DateTime date, {required bool isCurrentMonth}) {
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final isSelectable = _isSelectableDate(date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSelectable && isCurrentMonth ? () => _selectDate(date) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [Colors.blue[500]!, Colors.indigo[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isSelected
                ? null
                : isToday && isCurrentMonth
                ? Colors.blue[100]
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isToday && isCurrentMonth
                    ? Colors.blue[700]
                    : isCurrentMonth
                    ? isSelectable
                    ? Colors.grey[800]
                    : Colors.grey[400]
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isSelectableDate(DateTime date) {
    if (widget.firstDate != null && date.isBefore(widget.firstDate!)) {
      return false;
    }
    if (widget.lastDate != null && date.isAfter(widget.lastDate!)) {
      return false;
    }
    return true;
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// Helper function to show the calendar picker
Future<DateTime?> showModernCalendarPicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = 'Sélectionner une date',
}) async {
  DateTime? selectedDate;

  await showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ModernCalendarPicker(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      onDateSelected: (date) {
        selectedDate = date;
      },
    ),
  );

  return selectedDate;
}

// Optional: Calendar button widget for easy integration
class CalendarButton extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final String? label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CalendarButton({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.label,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<CalendarButton> createState() => _CalendarButtonState();
}

class _CalendarButtonState extends State<CalendarButton> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showModernCalendarPicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          title: widget.label ?? 'Sélectionner une date',
        );

        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
          widget.onDateSelected(date);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[500],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label ?? 'Date sélectionnée',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}