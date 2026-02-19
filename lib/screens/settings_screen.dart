import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jcc_reminder/screens/auth_gate.dart';
import 'package:jcc_reminder/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  final AuthService _authService = AuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    try {
      if (value) {
        await _authService.subscribeToNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications have been enabled.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _authService.unsubscribeFromNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications have been disabled.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error toggling notifications: $e");
      if (mounted) {
        setState(() => _notificationsEnabled = !value);
        await prefs.setBool('notifications_enabled', !value);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not update notification settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await _authService.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isLoading = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
      final sendTestNotification = functions.httpsCallable(
        'sendTestNotification',
      );
      await sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent! Check your device.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERROR: ${e.code.toUpperCase()} - ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          if (_currentUser != null)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: _currentUser!.photoURL != null
                          ? NetworkImage(_currentUser!.photoURL!)
                          : null,
                      child: _currentUser!.photoURL == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser!.displayName ?? 'User',
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (_currentUser!.email != null)
                            Text(
                              _currentUser!.email!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Allow the app to send reminders'),
              value: _notificationsEnabled,
              onChanged: _isLoading ? null : _toggleNotifications,
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Send Test Notification'),
              enabled: _notificationsEnabled && !_isLoading,
              leading: const Icon(Icons.notifications_active_outlined),
              trailing: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              onTap: _isLoading || !_notificationsEnabled
                  ? null
                  : _sendTestNotification,
            ),
          ),
          Card(
            child: const ListTile(
              title: Text('App Version'),
              subtitle: Text('v1.9.3'),
              leading: Icon(Icons.info_outline),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              title: Text(
                'Sign Out',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              onTap: () => _signOut(context),
            ),
          ),
        ],
      ),
    );
  }
}
