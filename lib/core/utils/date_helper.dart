// Date utilities
class DateHelper {
  // Formatters communs (sans dépendance externe)
  static const List<String> _monthNames = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  ];

  /// Formate une date au format court (DD/MM/YYYY)
  static String toShortDateString(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  /// Formate une date au format long (DD Mois YYYY)
  static String toLongDateString(DateTime date) {
    return "${date.day} ${_monthNames[date.month - 1]} ${date.year}";
  }

  /// Formate une date avec l'heure (DD/MM/YYYY HH:MM)
  static String toDateTimeString(DateTime date) {
    return "${toShortDateString(date)} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  /// Formate seulement l'heure (HH:MM)
  static String toTimeString(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  /// Formate au format Mois Année
  static String toMonthYearString(DateTime date) {
    return "${_monthNames[date.month - 1]} ${date.year}";
  }

  /// Calcule le nombre de jours entre deux dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Vérifie si une date est expirée
  static bool isExpired(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Vérifie si une date expire bientôt (dans les N jours)
  static bool isExpiringSoon(DateTime date, {int days = 30}) {
    final now = DateTime.now();
    final threshold = now.add(Duration(days: days));
    return date.isAfter(now) && date.isBefore(threshold);
  }

  /// Retourne le nombre de jours avant expiration
  static int daysUntilExpiry(DateTime expiryDate) {
    return daysBetween(DateTime.now(), expiryDate);
  }

  /// Formate une durée en français
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} jour${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} heure${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'moins d\'une minute';
    }
  }

  /// Retourne une chaîne relative (il y a X jours, dans X jours)
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      // Date passée
      final absDifference = difference.abs();
      if (absDifference.inDays > 0) {
        return 'il y a ${absDifference.inDays} jour${absDifference.inDays > 1 ? 's' : ''}';
      } else if (absDifference.inHours > 0) {
        return 'il y a ${absDifference.inHours} heure${absDifference.inHours > 1 ? 's' : ''}';
      } else if (absDifference.inMinutes > 0) {
        return 'il y a ${absDifference.inMinutes} minute${absDifference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'à l\'instant';
      }
    } else {
      // Date future
      if (difference.inDays > 0) {
        return 'dans ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'dans ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'dans ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'maintenant';
      }
    }
  }

  /// Vérifie si deux dates sont le même jour
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Retourne le début de la journée (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Retourne la fin de la journée (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Ajoute des mois à une date
  static DateTime addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day);
  }

  /// Ajoute des années à une date
  static DateTime addYears(DateTime date, int years) {
    return DateTime(date.year + years, date.month, date.day);
  }

  /// Parse une date depuis une chaîne DD/MM/YYYY
  static DateTime? parseShortDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Retourne la couleur selon l'état d'expiration
  static ExpiryStatus getExpiryStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final daysUntil = daysBetween(now, expiryDate);

    if (daysUntil < 0) {
      return ExpiryStatus.expired;
    } else if (daysUntil <= 7) {
      return ExpiryStatus.critical;
    } else if (daysUntil <= 30) {
      return ExpiryStatus.warning;
    } else {
      return ExpiryStatus.ok;
    }
  }
}

/// Status d'expiration pour les documents
enum ExpiryStatus {
  expired,    // Expiré
  critical,   // Expire dans moins de 7 jours
  warning,    // Expire dans moins de 30 jours
  ok,         // OK
}

/// Extension pour DateTime
extension DateTimeExtension on DateTime {
  /// Formate au format court
  String toShortString() => DateHelper.toShortDateString(this);

  /// Formate au format long
  String toLongString() => DateHelper.toLongDateString(this);

  /// Vérifie si la date est expirée
  bool get isExpired => DateHelper.isExpired(this);

  /// Vérifie si la date expire bientôt
  bool isExpiringSoon({int days = 30}) => DateHelper.isExpiringSoon(this, days: days);

  /// Retourne le nombre de jours jusqu'à expiration
  int get daysUntilExpiry => DateHelper.daysUntilExpiry(this);

  /// Retourne le temps relatif
  String get relativeTime => DateHelper.getRelativeTime(this);

  /// Retourne le status d'expiration
  ExpiryStatus get expiryStatus => DateHelper.getExpiryStatus(this);
}