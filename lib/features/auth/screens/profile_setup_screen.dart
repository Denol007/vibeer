import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/age_confirmation_checkbox.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../../profile/services/profile_service.dart';

/// Profile setup screen for completing user profile after OAuth
///
/// Collects required information: age, photo, about me, age confirmation.
/// Pre-fills name from OAuth data. Validates all fields before submission.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _aboutMeController = TextEditingController();

  File? _profilePhoto;
  bool _ageConfirmed = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showAgeConfirmError = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // Pre-fill name from OAuth data
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser != null) {
      _nameController.text = currentUser.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profilePhoto = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка выбора фото';
      });
    }
  }

  Future<void> _submitProfile() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate age confirmation
    if (!_ageConfirmed) {
      setState(() {
        _showAgeConfirmError = true;
      });
      return;
    }

    // Validate photo
    if (_profilePhoto == null) {
      setState(() {
        _errorMessage = 'Необходимо загрузить фото профиля';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showAgeConfirmError = false;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      await profileService.createProfile(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        profilePhoto: _profilePhoto!,
        aboutMe: _aboutMeController.text.trim(),
        ageConfirmed: _ageConfirmed,
      );

      // Navigate to home screen after successful profile creation
      if (mounted) {
        context.go('/home');
      }
    } on ProfileValidationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on ProfileUploadException catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки фото: ${e.message}';
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
      appBar: AppBar(title: const Text('Настройка профиля')),
      body: _isLoading
          ? const LoadingIndicator()
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile photo
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickPhoto,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.background,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  image: _profilePhoto != null
                                      ? DecorationImage(
                                          image: FileImage(_profilePhoto!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _profilePhoto == null
                                    ? Icon(
                                        Icons.add_a_photo,
                                        size: 40,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _pickPhoto,
                              child: const Text('Upload Photo'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Name field (pre-filled, read-only)
                      TextFormField(
                        controller: _nameController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Имя',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Age field
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Возраст',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.cake),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите ваш возраст';
                          }
                          final age = int.tryParse(value);
                          if (age == null) {
                            return 'Введите корректный возраст';
                          }
                          if (age < 18) {
                            return 'Must be 18 or older';
                          }
                          if (age > 25) {
                            return 'Возраст должен быть 18-25 лет';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // About me field
                      TextFormField(
                        controller: _aboutMeController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'О себе',
                          border: OutlineInputBorder(),
                          hintText: 'Расскажите немного о себе...',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Напишите что-нибудь о себе';
                          }
                          if (value.trim().length < 10) {
                            return 'Минимум 10 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Age confirmation checkbox
                      AgeConfirmationCheckbox(
                        value: _ageConfirmed,
                        onChanged: (value) {
                          setState(() {
                            _ageConfirmed = value ?? false;
                            _showAgeConfirmError = false;
                          });
                        },
                        showError: _showAgeConfirmError,
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
                        text: 'Complete Profile',
                        onPressed: _submitProfile,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
