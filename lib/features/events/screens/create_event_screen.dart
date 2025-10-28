import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/events_provider.dart';
import '../widgets/location_picker.dart';
import '../widgets/category_selector.dart';
import '../services/events_service.dart';
import '../models/event_category.dart';

/// Create event screen with form for event details
///
/// Collects title, description, location, time, and participant count.
/// Validates all fields and creates event via EventsService.
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  GeoPoint? _selectedLocation;
  String? _locationName;
  DateTime? _selectedTime;
  EventCategory _selectedCategory = EventCategory.other; // Default category
  int _neededParticipants =
      2; // Default: need 2 more people (3 total with organizer)

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          initialLocation: _selectedLocation != null
              ? LatLng(
                  _selectedLocation!.latitude,
                  _selectedLocation!.longitude,
                )
              : null,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['location'] as GeoPoint;
        _locationName = result['locationName'] as String;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final maxDate = now.add(
      const Duration(days: 365),
    ); // Allow up to 1 year ahead

    // Show date picker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedTime ?? now,
      firstDate: now,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    // If time was already selected, keep that time, otherwise set to 1 hour from now
    if (_selectedTime != null) {
      setState(() {
        _selectedTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      });
    } else {
      final initialTime = now.add(const Duration(hours: 1));
      setState(() {
        _selectedTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          initialTime.hour,
          initialTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();

    // Show time picker
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: AppColors.primary.withAlpha(51),
              hourMinuteTextColor: AppColors.primary,
              dialHandColor: AppColors.primary,
              dialBackgroundColor: AppColors.background,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    // Use selected date or today
    final baseDate = _selectedTime ?? now;
    final selectedDateTime = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validate that event is in the future
    if (selectedDateTime.isBefore(now)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Событие должно начаться в будущем')),
        );
      }
      return;
    }

    setState(() {
      _selectedTime = selectedDateTime;
    });
  }

  void _setStartNow() {
    setState(() {
      _selectedTime = DateTime.now().add(const Duration(minutes: 5));
    });
  }

  String _formatSelectedDate() {
    if (_selectedTime == null) return 'Дата';

    final now = DateTime.now();
    if (now.day == _selectedTime!.day &&
        now.month == _selectedTime!.month &&
        now.year == _selectedTime!.year) {
      return 'Сегодня';
    } else if (_selectedTime!.difference(now).inDays == 0 &&
        _selectedTime!.day == now.day + 1) {
      return 'Завтра';
    } else {
      // Format as DD.MM.YYYY
      return '${_selectedTime!.day.toString().padLeft(2, '0')}.${_selectedTime!.month.toString().padLeft(2, '0')}.${_selectedTime!.year}';
    }
  }

  String _formatSelectedTimeOnly() {
    if (_selectedTime == null) return 'Время';

    return '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitEvent() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate location
    if (_selectedLocation == null) {
      setState(() {
        _errorMessage = 'Выберите место события';
      });
      return;
    }

    // Validate time
    if (_selectedTime == null) {
      setState(() {
        _errorMessage = 'Выберите время начала';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eventsService = ref.read(eventsServiceProvider);
      await eventsService.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        location: _selectedLocation!,
        locationName: _locationName,
        startTime: _selectedTime!,
        neededParticipants: _neededParticipants,
      );

      // Navigate back on success
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Событие создано!')));
      }
    } on EventValidationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on EventException catch (e) {
      setState(() {
        _errorMessage = 'Ошибка: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка. Попробуйте снова.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Создать событие')),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Название события',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      maxLength: 100,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите название';
                        }
                        if (value.trim().length < 3) {
                          return 'Минимум 3 символа';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(),
                        hintText: 'Расскажите о событии...',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      maxLength: 500,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите описание';
                        }
                        if (value.trim().length < 10) {
                          return 'Минимум 10 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Category selector
                    const Text(
                      'Категория события',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CategorySelector(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      showAllCategories: true,
                    ),
                    const SizedBox(height: 24),

                    // Location picker button
                    OutlinedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.location_on),
                      label: Text(
                        _locationName ?? 'Выбрать место',
                        style: TextStyle(
                          color: _locationName != null
                              ? AppColors.primary
                              : Colors.grey[700],
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        side: BorderSide(
                          color: _locationName != null
                              ? AppColors.primary
                              : Colors.grey[400]!,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date and Time pickers in a row
                    Row(
                      children: [
                        // Date picker
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _formatSelectedDate(),
                              style: TextStyle(
                                color: _selectedTime != null
                                    ? AppColors.primary
                                    : Colors.grey[700],
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              side: BorderSide(
                                color: _selectedTime != null
                                    ? AppColors.primary
                                    : Colors.grey[400]!,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Time picker
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _formatSelectedTimeOnly(),
                              style: TextStyle(
                                color: _selectedTime != null
                                    ? AppColors.primary
                                    : Colors.grey[700],
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              side: BorderSide(
                                color: _selectedTime != null
                                    ? AppColors.primary
                                    : Colors.grey[400]!,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // "Start now" quick option
                    TextButton(
                      onPressed: _setStartNow,
                      child: const Text('Начать сейчас'),
                    ),
                    const SizedBox(height: 16),

                    // Participants stepper
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Сколько людей нужно?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Всего участников: ${_neededParticipants + 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: _neededParticipants > 1
                                          ? () {
                                              setState(() {
                                                _neededParticipants--;
                                              });
                                            }
                                          : null,
                                      color: AppColors.primary,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(26),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$_neededParticipants',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: _neededParticipants < 5
                                          ? () {
                                              setState(() {
                                                _neededParticipants++;
                                              });
                                            }
                                          : null,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Вы + $_neededParticipants человек',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Submit button
                    CustomButton(
                      text: 'Создать событие',
                      onPressed: _submitEvent,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
