// utils/form_field_helper.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'platform_helper.dart';
import 'task_helper.dart';

class FormFieldHelper {
  // Platform selection field
  static Widget buildPlatformField({
    required String selectedPlatform,
    required ValueChanged<String?> onChanged,
    String? label,
    List<String>? allowedPlatforms,
    bool required = true,
  }) {
    final platforms = allowedPlatforms ?? PlatformHelper.getAllPlatforms();

    return DropdownButtonFormField<String>(
      value: selectedPlatform.isNotEmpty ? selectedPlatform : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label ?? 'Select Platform',
        border: const OutlineInputBorder(),
        prefixIcon:
            selectedPlatform.isNotEmpty
                ? Icon(PlatformHelper.getPlatformIcon(selectedPlatform))
                : const Icon(Icons.public),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('Select a platform...'),
        ),
        ...platforms.map((platform) {
          return DropdownMenuItem<String>(
            value: platform,
            child: Row(
              children: [
                Icon(
                  PlatformHelper.getPlatformIcon(platform),
                  color: PlatformHelper.getPlatformColor(platform),
                ),
                const SizedBox(width: 10),
                Text(PlatformHelper.getPlatformDisplayName(platform)),
              ],
            ),
          );
        }).toList(),
      ],
      validator:
          required
              ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a platform';
                }
                if (!PlatformHelper.isValidPlatform(value)) {
                  return 'Please select a valid platform';
                }
                return null;
              }
              : null,
    );
  }

  static InputDecoration getInputDecoration({
    required String hint,
    required ThemeData theme,
    IconData? prefixIcon,
    String? label,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: theme.hintColor) : null,
      filled: true,
      fillColor: theme.cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  // Task type selection field
  static Widget buildTaskTypeField({
    required String selectedType,
    required ValueChanged<String?> onChanged,
    String? label,
  }) {
    final taskTypes = TaskHelper.taskCategories;

    return DropdownButtonFormField<String>(
      value: selectedType.isNotEmpty ? selectedType : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label ?? 'Task Type',
        border: const OutlineInputBorder(),
        prefixIcon:
            selectedType.isNotEmpty
                ? Icon(TaskHelper.getTaskCategoryIcon(selectedType))
                : const Icon(Icons.task),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('Select task type...'),
        ),
        ...taskTypes.map((type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Row(
              children: [
                Icon(
                  TaskHelper.getTaskCategoryIcon(type),
                  color: TaskHelper.getTaskCategoryColor(type),
                ),
                const SizedBox(width: 10),
                Text(TaskHelper.getTaskCategoryDisplayName(type)),
              ],
            ),
          );
        }).toList(),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a task type';
        }
        return null;
      },
    );
  }

  // Quantity field with validation
  static Widget buildQuantityField({
    required TextEditingController controller,
    required String taskType,
    String? label,
  }) {
    final requirements = TaskHelper.getTaskRequirements(taskType);
    final min = requirements['quantity_min'] as int;
    final max = requirements['quantity_max'] as int;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label ?? 'Quantity',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.numbers),
        suffixText: '($min-$max)',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter quantity';
        }
        final quantity = int.tryParse(value);
        if (quantity == null) {
          return 'Please enter a valid number';
        }
        if (quantity < min) {
          return 'Minimum quantity is $min';
        }
        if (quantity > max) {
          return 'Maximum quantity is $max';
        }
        return null;
      },
    );
  }

  // Duration field for advert tasks
  static Widget buildDurationField({
    required TextEditingController controller,
    String? label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label ?? 'Duration (hours)',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.timer),
        suffixText: 'hours',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter duration';
        }
        final duration = int.tryParse(value);
        if (duration == null) {
          return 'Please enter a valid number';
        }
        if (duration < 1) {
          return 'Minimum duration is 1 hour';
        }
        if (duration > 168) {
          return 'Maximum duration is 168 hours (7 days)';
        }
        return null;
      },
    );
  }

  // Price field with validation
  static Widget buildPriceField({
    required TextEditingController controller,
    required String taskType,
    String? label,
  }) {
    final pricing = TaskHelper.getTaskPricingSuggestions(taskType);
    final min = pricing['min_price'] as double;
    final max = pricing['max_price'] as double;
    final unit = pricing['price_unit'] as String;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label ?? 'Price per unit',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.attach_money),
        suffixText: 'NGN/$unit',
        hintText: 'e.g., ${pricing['suggested_price']}',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter price';
        }
        final price = double.tryParse(value);
        if (price == null) {
          return 'Please enter a valid price';
        }
        if (price < min) {
          return 'Minimum price is ₦$min';
        }
        if (price > max) {
          return 'Maximum price is ₦$max';
        }
        return null;
      },
    );
  }

  // Gender selection field
  static Widget buildGenderField({
    required String selectedGender,
    required ValueChanged<String?> onChanged,
    String? label,
  }) {
    const genders = ['All Gender', 'Male', 'Female'];

    return DropdownButtonFormField<String>(
      value: selectedGender,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label ?? 'Target Gender',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.person),
      ),
      items:
          genders
              .map(
                (gender) => DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                ),
              )
              .toList(),
    );
  }

  // Religion selection field
  static Widget buildReligionField({
    required String selectedReligion,
    required ValueChanged<String?> onChanged,
    String? label,
  }) {
    const religions = ['All Religion', 'Christianity', 'Islam', 'Others'];

    return DropdownButtonFormField<String>(
      value: selectedReligion,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label ?? 'Target Religion',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.church),
      ),
      items:
          religions
              .map(
                (religion) => DropdownMenuItem<String>(
                  value: religion,
                  child: Text(religion),
                ),
              )
              .toList(),
    );
  }

  // Media type selection
  static Widget buildMediaTypeField({
    required String selectedType,
    required ValueChanged<String?> onChanged,
    String? label,
  }) {
    final mediaTypes = [
      {'value': 'photo', 'label': 'Photo', 'icon': Icons.photo},
      {'value': 'video', 'label': 'Video', 'icon': Icons.videocam},
      {'value': 'gif', 'label': 'GIF', 'icon': Icons.gif},
      {'value': 'text', 'label': 'Text Only', 'icon': Icons.text_fields},
    ];

    return DropdownButtonFormField<String>(
      value: selectedType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label ?? 'Media Type',
        border: const OutlineInputBorder(),
      ),
      items:
          mediaTypes
              .map(
                (type) => DropdownMenuItem<String>(
                  value: type['value'] as String,
                  child: Row(
                    children: [
                      Icon(type['icon'] as IconData),
                      const SizedBox(width: 10),
                      Text(type['label'] as String),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  // Calculate total price
  static double calculateTotalPrice({
    required double unitPrice,
    required int quantity,
    double discount = 0.0,
  }) {
    double total = unitPrice * quantity;
    if (discount > 0) {
      total -= total * (discount / 100);
    }
    return total;
  }

  // Format currency
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    return formatter.format(amount);
  }


  // Validate form
  static Map<String, String>? validateTaskForm({
    required String platform,
    required String taskType,
    required String quantity,
    required String unitPrice,
    String? mediaType,
    String? duration,
  }) {
    final errors = <String, String>{};

    if (platform.isEmpty) {
      errors['platform'] = 'Platform is required';
    } else if (!PlatformHelper.isValidPlatform(platform)) {
      errors['platform'] = 'Invalid platform selected';
    }

    if (taskType.isEmpty) {
      errors['taskType'] = 'Task type is required';
    }

    if (quantity.isEmpty) {
      errors['quantity'] = 'Quantity is required';
    } else {
      final qty = int.tryParse(quantity);
      if (qty == null) {
        errors['quantity'] = 'Invalid quantity';
      } else {
        final requirements = TaskHelper.getTaskRequirements(taskType);
        final quantityMin = requirements['quantity_min'] as int;
        final quantityMax = requirements['quantity_max'] as int;

        if (qty < quantityMin) {
          errors['quantity'] = 'Minimum quantity is $quantityMin';
        }
        if (qty > quantityMax) {
          errors['quantity'] = 'Maximum quantity is $quantityMax';
        }
      }
    }

    if (unitPrice.isEmpty) {
      errors['unitPrice'] = 'Price is required';
    } else {
      final price = double.tryParse(unitPrice);
      if (price == null) {
        errors['unitPrice'] = 'Invalid price';
      } else {
        final pricing = TaskHelper.getTaskPricingSuggestions(taskType);
        final minPrice = pricing['min_price'] as double;
        final maxPrice = pricing['max_price'] as double;

        if (price < minPrice) {
          errors['unitPrice'] = 'Minimum price is ₦$minPrice';
        }
        if (price > maxPrice) {
          errors['unitPrice'] = 'Maximum price is ₦$maxPrice';
        }
      }
    }

    // Validate platform for task type
    if (platform.isNotEmpty && taskType.isNotEmpty) {
      if (!TaskHelper.validateTaskForPlatform(taskType, platform)) {
        errors['platform'] = 'This task type is not supported on $platform';
      }
    }

    return errors.isEmpty ? null : errors;
  }
}
