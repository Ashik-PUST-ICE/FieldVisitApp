import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/constants/app_constants.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/core/widgets/tunneled_image.dart';
import 'package:field_visit_app/presentation/providers/auth_api_provider.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountState();
}

class _AccountState extends ConsumerState<AccountScreen> {
  final first = TextEditingController();
  final last = TextEditingController();
  final mobile = TextEditingController();

  bool _isUpdatingProfile = false;
  bool _isUploadingImage = false;

  /// URL whose `NetworkImage` failed to load, so the avatar falls back to the
  /// initials. Tracked by value so a fresh URL is retried automatically.
  String? _avatarFailedUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    if (user != null) {
      final parts = user.fullName.split(' ');
      first.text = parts.isNotEmpty ? parts.first : '';
      last.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    mobile.dispose();
    super.dispose();
  }

  /// Pulls the saved avatar URL straight out of the PUT response.
  ///
  /// Reading it from the provider after `getProfile()` was unreliable: that
  /// notifier swallows failures and leaves the state as `AsyncValue.error`, so
  /// `valueOrNull` became null and the UI wrongly reported
  /// "Image uploaded but not returned by server".
  String? _imageFrom(Response<dynamic> response) {
    final data = response.data;
    if (data is! Map) return null;
    final body = data['data'];
    if (body is! Map) return null;
    final user = body['user'];
    if (user is! Map) return null;
    final url = user['image'];
    return url is String && url.isNotEmpty ? url : null;
  }

  Future<void> _pickAndUploadImage() async {
    // Resolve the messenger BEFORE the first await. After an async gap this
    // element can be deactivated (the screen is popped / reparented while the
    // gallery picker is open), and `ScaffoldMessenger.of(context)` then throws
    // "Looking up a deactivated widget's ancestor is unsafe".
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;
    setState(() => _isUploadingImage = true);
    try {
      final response = await ref.read(authApiProvider).updateProfileWithImage(
            bytes: await picked.readAsBytes(),
            filename: picked.name,
          );
      final savedUrl = _imageFrom(response);
      if (savedUrl != null) _avatarFailedUrl = null;
      await ref.read(authProvider.notifier).getProfile();
      final hasImage = savedUrl != null;
      messenger.showSnackBar(
        SnackBar(
          content: Text(hasImage
              ? tr(ref, 'profileImageUpdated')
              : tr(ref, 'imageNotReturned')),
          backgroundColor: hasImage ? AppColors.success : AppColors.warning,
        ),
      );
    } catch (e) {
      _show(messenger, e);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> profile() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isUpdatingProfile = true);
    try {
      await ref.read(authApiProvider).updateProfile({
        'first_name': first.text.trim(),
        'last_name': last.text.trim(),
        'mobile': mobile.text.trim(),
      });
      await ref.read(authProvider.notifier).getProfile();
      messenger.showSnackBar(
        SnackBar(content: Text(tr(ref, 'profileUpdated'))),
      );
    } catch (e) {
      _show(messenger, e);
    } finally {
      if (mounted) setState(() => _isUpdatingProfile = false);
    }
  }

  void _show(ScaffoldMessengerState messenger, Object e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          e is DioException && e.response?.data is Map
              ? ((e.response!.data as Map)['message'] ??
                      (e.response!.data as Map)['errors'])
                  .toString()
              : e.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = user != null && user.fullName.isNotEmpty
        ? user.fullName[0].toUpperCase()
        : 'U';
    // The API returns a laptop-only absolute URL; rewrite it onto the local
    // tunnel so the device can actually fetch the bytes.
    final imageUrl = AppConstants.resolveMediaUrl(user?.image);
    // `hasImage` alone is not enough: once a `backgroundImage` is set the
    // `child` is not rendered, so a failed load would leave a blank circle.
    // Drop the image when THIS url already failed so the initials come back.
    final showImage = imageUrl.isNotEmpty && _avatarFailedUrl != imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'myProfile'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0D9488),
                  Color(0xFF0891B2),
                  Color(0xFF0284C7)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            showImage ? TunneledNetworkImage(imageUrl) : null,
                        onBackgroundImageError: showImage
                            ? (_, __) {
                                // Swap back to the initials instead of leaving
                                // an empty circle behind.
                                if (!mounted) return;
                                setState(() => _avatarFailedUrl = imageUrl);
                              }
                            : null,
                        child: showImage
                            ? null
                            : Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF136B3E)))
                            : const Icon(Icons.camera_alt_rounded,
                                size: 16, color: Color(0xFF136B3E)),
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
                        user?.fullName ?? tr(ref, 'fieldOfficerTitle'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'officer@fieldvisit.com',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user?.roles?.isNotEmpty == true
                              ? (user!.roles as List).join(' • ')
                              : tr(ref, 'fieldOpsSpecialist'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Personal Details Section
          _buildSectionCard(
            context,
            isDark: isDark,
            title: tr(ref, 'personalDetails'),
            icon: Icons.badge_outlined,
            children: [
              CellfinInputField(
                controller: first,
                hint: tr(ref, 'firstName'),
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              CellfinInputField(
                controller: last,
                hint: tr(ref, 'lastName'),
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              CellfinInputField(
                controller: mobile,
                keyboardType: TextInputType.phone,
                hint: tr(ref, 'mobileNumber'),
                prefixIcon:
                    const Icon(Icons.phone_outlined, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF136B3E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _isUpdatingProfile ? null : profile,
                child: _isUpdatingProfile
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(tr(ref, 'submitProfileChanges'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Logout Action
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(tr(ref, 'logOutFieldVisit'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
