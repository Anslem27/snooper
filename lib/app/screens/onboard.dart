import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

class DiscordOnboardingScreen extends StatefulWidget {
  final Function(String) onUserIdSubmitted;

  const DiscordOnboardingScreen({
    super.key,
    required this.onUserIdSubmitted,
  });

  @override
  State<DiscordOnboardingScreen> createState() =>
      _DiscordOnboardingScreenState();
}

class _DiscordOnboardingScreenState extends State<DiscordOnboardingScreen> {
  final TextEditingController _userIdController = TextEditingController();

  List<Map<String, String>> imageDetails = List.generate(
    3,
    (index) => {
      "Step ${index + 1}": index != 1
          ? "assets/onboard/${index + 1}.webp"
          : "assets/onboard/${index + 1}.jpg",
    },
  );

  @override
  initState() {
    super.initState();
  }

  bool _isValidating = false;
  String? _errorMessage;
  int _currentStep = 0;
  bool _showImageInstructions = false;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSubmitUserId() async {
    final userId = _userIdController.text.trim();

    if (userId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your Discord user ID';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.lanyard.rest/v1/users/$userId'),
      );

      if (response.statusCode == 200) {
        // Valid user ID
        widget.onUserIdSubmitted(userId);
      } else {
        setState(() {
          _isValidating = false;
          _errorMessage =
              'Invalid Discord user ID. Please check and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isValidating = false;
        _errorMessage =
            'Network error. Please check your connection and try again.';
      });
    }
  }

  void _toggleImageInstructions() {
    setState(() {
      _showImageInstructions = !_showImageInstructions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() {
                  _currentStep += 1;
                });
              } else {
                _validateAndSubmitUserId();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() {
                  _currentStep -= 1;
                });
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: [
                    if (_currentStep == 2)
                      Expanded(
                        child: FilledButton(
                          onPressed: _isValidating
                              ? null
                              : () => _validateAndSubmitUserId(),
                          child: _isValidating
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.0),
                                )
                              : const Text('Get Started'),
                        ),
                      )
                    else
                      Expanded(
                        child: FilledButton(
                          onPressed: details.onStepContinue,
                          child: Text(
                              _currentStep == 2 ? 'Get Started' : 'Continue'),
                        ),
                      ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Welcome'),
                content: _buildWelcomeStep(),
                isActive: _currentStep >= 0,
              ),
              Step(
                title: const Text('Discord ID'),
                content: _buildDiscordIdStep(),
                isActive: _currentStep >= 1,
              ),
              Step(
                title: const Text('Complete'),
                content: _buildCompleteStep(),
                isActive: _currentStep >= 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(50),
          ),
          child: SvgPicture.asset(
            'assets/branding/transparent_small.svg',
            // height: 20,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.primary,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to Snooper!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Track your Discord activity and share it with friends. Let\'s get started by setting up your Discord account.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'What you\'ll need:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Your Discord user ID'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Discord Developer Mode enabled'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Join the Lanyard discord server.'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscordIdStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your Discord User ID',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _userIdController,
          decoration: InputDecoration(
            labelText: 'Discord User ID',
            hintText: 'Example: 123456789012345678',
            prefixIcon: const Icon(Icons.tag),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            errorText: _errorMessage,
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'How to find your Discord User ID:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Open Discord app settings',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const Text(
                  '2. Go to Advanced and enable Developer Mode',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const Text(
                  '3. Right-click your username and select "Copy ID"',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _toggleImageInstructions,
                  icon: Icon(
                    _showImageInstructions
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                  ),
                  label: Text(
                    _showImageInstructions
                        ? 'Hide visual instructions | TAP TO ZOOM'
                        : 'See visual instructions',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_showImageInstructions) ...[
                  const SizedBox(height: 16),
                  _buildImageInstructions(),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your Discord ID is a long number that uniquely identifies your account.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageInstructions() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < imageDetails.length; i++) ...[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${i + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: InteractiveViewer(
                              child: Image.asset(
                                imageDetails[i]['Step ${i + 1}']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'imageHero${i + 1}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          imageDetails[i]['Step ${i + 1}']!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i == 0
                        ? 'Open Discord settings and navigate to Advanced'
                        : i == 1
                            ? 'Enable Developer Mode'
                            : 'Right-click on your username and select "Copy ID"',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (i < imageDetails.length - 1)
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            Icons.check_circle,
            size: 50,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Almost there!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Once you click "Get Started", we\'ll verify your Discord ID and set up your profile.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Privacy Note:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'We only use your Discord ID to fetch public activity data through the Lanyard API. Your ID is stored locally on your device and isn\'t shared with anyone else.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
