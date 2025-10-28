import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Edit Profile Screen - T058
///
/// Form for editing user profile.
/// Allows changing profile photo, age, and about me text.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  /// Load current profile data
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final profileService = ref.read(profileServiceProvider);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      final profile = await profileService.getProfile(currentUser.id);

      if (profile == null) {
        throw Exception('Профиль не найден');
      }

      if (mounted) {
        setState(() {
          _ageController.text = profile.age.toString();
          _aboutMeController.text = profile.aboutMe ?? '';
          _currentPhotoUrl = profile.profilePhotoUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора изображения: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка съёмки: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Show photo source selection dialog
  Future<void> _showPhotoSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выбрать фото'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Камера'),
              onTap: () {
                Navigator.of(context).pop();
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Validate age field
  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Укажите возраст';
    }

    final age = int.tryParse(value);
    return validateAge(age);
  }

  /// Validate about me field
  String? _validateAboutMe(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    return validateTextLength(value, 500, minLength: 0, fieldName: 'О себе');
  }

  /// Save profile changes
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final profileService = ref.read(profileServiceProvider);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Update profile using the service's updateProfile method
      await profileService.updateProfile(
        age: int.parse(_ageController.text),
        newProfilePhoto: _selectedImage,
        aboutMe: _aboutMeController.text.trim().isEmpty
            ? null
            : _aboutMeController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Профиль обновлён!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редактировать профиль')),
        body: const Center(child: LoadingIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile photo section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : _currentPhotoUrl != null
                          ? CachedNetworkImageProvider(_currentPhotoUrl!)
                          : null,
                      child: _selectedImage == null && _currentPhotoUrl == null
                          ? const Icon(Icons.person, size: 64)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _isSaving ? null : _showPhotoSourceDialog,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Age field
              CustomTextField(
                controller: _ageController,
                labelText: 'Возраст *',
                hintText: 'Ваш возраст',
                keyboardType: TextInputType.number,
                enabled: !_isSaving,
                validator: _validateAge,
              ),
              const SizedBox(height: 16),

              // About me field
              CustomTextField(
                controller: _aboutMeController,
                labelText: 'О себе',
                hintText: 'Расскажите о себе...',
                maxLines: 5,
                minLines: 3,
                maxLength: 500,
                enabled: !_isSaving,
                validator: _validateAboutMe,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Save button
              CustomButton(
                text: 'Сохранить изменения',
                onPressed: _isSaving ? null : _saveProfile,
                isLoading: _isSaving,
                icon: Icons.check,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
