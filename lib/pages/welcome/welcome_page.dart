import 'package:gobeller/const/const_ui.dart';
import 'package:gobeller/utils/routes.dart';
import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Body
            Expanded(
              child: Padding(
                padding: ConstUI.kMainPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    // TODO: Replace with your own logo
                    Image.asset(
                      "assets/logo.png",
                      width: 188,
                      height: 188,
                    ),
                    const SizedBox(height: 32),

                    // Title
                    // TODO: Replace with your own title
                    Text(
                      "Welcome to SDDTIF Thrift",
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    // TODO: Replace with your own subtitle
                    Text(
                      "We are here to help you achieve your goals, by tracking your income and expense daily. ",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Action Button
            Padding(
              padding: ConstUI.kMainPadding,
              child: Row(
                children: [
                  // Login
                  Expanded(
                    child: OutlinedButton(
                      child: const Text("Login"),
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.login);
                      },
                    ),
                  ),

                  // Gap
                  const SizedBox(width: 16),

                  // Register
                  Expanded(
                    child: FilledButton(
                      child: const Text("Register"),
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.register);

                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
