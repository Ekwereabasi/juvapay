enum NotificationType {
  system,
  order,
  transaction,
  support,
  task,
  wallet,
  promotion,
  security,
}

enum NotificationStatus { unread, read, archived }

enum NotificationPriority { low, medium, high, urgent }

enum NotificationChannel { inApp, email, push, sms, whatsapp }
