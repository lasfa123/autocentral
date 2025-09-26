// lib/widgets/modern_date_picker.dart
import 'package:flutter/material.dart';

class ModernDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime) onDateSelected;
  final String title;

  const ModernDatePicker({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    required this.onDateSelected,
    this.title = 'Sélectionner une date',
  });

  @override
  State<ModernDatePicker> createState() => _ModernDatePickerState();
}

class _ModernDatePickerState extends State<ModernDatePicker> {
  late DateTime _currentDate;
  late DateTime _selectedDate;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _currentDate = DateTime(_selectedDate.year, _selectedDate.month);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Contrôles de navigation mois
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: const Icon(Icons.chevron_left, size: 24),
                    ),
                    Text(
                      _formatMonthYear(_currentDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right, size: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calendrier
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCalendar(),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Annuler'),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Sauvegarder'),
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
        // En-têtes des jours
        Row(
          children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        
        const SizedBox(height: 12),
        
        // Grille du calendrier
        Expanded(
          child: _buildCalendarGrid(),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7; // Ajuster pour dimanche = 0
    
    final days = <Widget>[];
    
    // Jours du mois précédent
    final prevMonth = DateTime(_currentDate.year, _currentDate.month - 1, 0);
    for (int i = firstDayWeekday - 1; i >= 0; i--) {
      final day = prevMonth.day - i;
      days.add(_buildDayCell(
        day,
        DateTime(_currentDate.year, _currentDate.month - 1, day),
        isCurrentMonth: false,
      ));
    }
    
    // Jours du mois actuel
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(_buildDayCell(
        day,
        DateTime(_currentDate.year, _currentDate.month, day),
        isCurrentMonth: true,
      ));
    }
    
    // Jours du mois suivant pour remplir la grille
    final remainingCells = 42 - days.length; // 6 lignes x 7 jours
    for (int day = 1; day <= remainingCells; day++) {
      days.add(_buildDayCell(
        day,
        DateTime(_currentDate.year, _currentDate.month + 1, day),
        isCurrentMonth: false,
      ));
    }
    
    return GridView.count(
      crossAxisCount: 7,
      children: days,
    );
  }

  Widget _buildDayCell(int day, DateTime date, {required bool isCurrentMonth}) {
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final isSelectable = _isSelectableDate(date);
    
    return GestureDetector(
      onTap: isSelectable && isCurrentMonth ? () => _selectDate(date) : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue[600]
              : isToday && isCurrentMonth
                  ? Colors.blue[50]
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected && isCurrentMonth
              ? Border.all(color: Colors.blue[300]!, width: 1)
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : isCurrentMonth
                      ? isSelectable
                          ? Colors.black
                          : Colors.grey[400]
                      : Colors.grey[300],
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
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
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

// Fonction helper pour afficher le date picker
Future<DateTime?> showModernDatePicker({
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
    builder: (context) => ModernDatePicker(
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