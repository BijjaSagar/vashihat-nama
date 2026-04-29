import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:ui';

class LegacyWizardScreen extends StatefulWidget {
  const LegacyWizardScreen({Key? key}) : super(key: key);

  @override
  _LegacyWizardScreenState createState() => _LegacyWizardScreenState();
}

class _LegacyWizardScreenState extends State<LegacyWizardScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _steps = [
    {
      "title": "Welcome to Your Sanctuary",
      "desc": "Vasihat Nama is more than a vault. It is a bridge between today and your loved ones' tomorrow.",
      "action": "Begin Your Legacy",
      "icon": "🛡️",
    },
    {
      "title": "Secure Your First Truth",
      "desc": "Upload a vital document. It will be shredded into 256-bit fragments, encrypted locally, and stored in your private cloud.",
      "action": "Choose a Document",
      "icon": "📄",
    },
    {
      "title": "Appoint Your Guardians",
      "desc": "Select the people you trust. They will only receive access if your heartbeat stops pulsing.",
      "action": "Add a Nominee",
      "icon": "👥",
    },
    {
      "title": "The Dead Man's Switch",
      "desc": "Set your check-in frequency. If you don't check in, we'll reach out. If there's no response, your legacy is released.",
      "action": "Set Heartbeat",
      "icon": "💓",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.05),
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container()),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Progress Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (index) => _buildProgressDot(index)),
                ),
                
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (val) => setState(() => _currentStep = val),
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_steps[index]['icon']!, style: const TextStyle(fontSize: 80)),
                            const SizedBox(height: 40),
                            Text(
                              _steps[index]['title']!,
                              textAlign: TextAlign.center,
                              style: AppTheme.darkTheme.textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _steps[index]['desc']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 18, height: 1.6),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_currentStep < _steps.length - 1) {
                            _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 64),
                          backgroundColor: AppTheme.accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          _steps[_currentStep]['action']!,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Skip for now", style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: _currentStep == index ? 24 : 6,
      decoration: BoxDecoration(
        color: _currentStep == index ? AppTheme.accentColor : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
