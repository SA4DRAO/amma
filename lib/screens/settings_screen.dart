import 'package:amma/screens/credits_screen.dart';
import 'package:amma/util/providers/dark_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amma/util/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(firebaseAuthProvider).currentUser;
    var darkMode = ref.watch(darkModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        if (user != null && user.photoURL != null)
          Column(
            children: [
              CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage(user.photoURL!),
              ),
              const SizedBox(height: 10),
              Text(
                user.displayName ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            await ref.read(authRepositoryProvider).signOut();
            Navigator.of(context).pop();
          },
          child: const Text('Logout'),
        ),
        ListTile(
          title: const Text('Credits'),
          onTap: () {
            // Use Builder widget to get a context that has access to the Navigator
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreditsScreen(),
              ),
            );
          },
        ),
        ListTile(
          title: const Text('Statistics'),
          onTap: () {
            // Navigate to statistics screen
          },
        ),
        SwitchListTile(
          title: const Text('Dark Mode'),
          value: darkMode,
          onChanged: (value) {
            ref.read(darkModeProvider.notifier).toggle();
          },
        ),
      ],
    );
  }
}
