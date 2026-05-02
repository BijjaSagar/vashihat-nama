import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LegacyWizardScreen extends StatefulWidget {
  const LegacyWizardScreen({super.key});

  @override
  _LegacyWizardScreenState createState() => _LegacyWizardScreenState();
}

class _LegacyWizardScreenState extends State<LegacyWizardScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _steps = [
    {
      "title": "WELCOME TO YOUR SANCTUARY",
      "desc": "SENTINEL IS MORE THAN A VAULT. IT IS A BRIDGE BETWEEN TODAY AND YOUR LOVED ONES' TOMORROW.",
      "action": "BEGIN YOUR LEGACY",
      "icon": "🛡️",
    },
    {
      "title": "SECURE YOUR FIRST TRUTH",
      "desc": "UPLOAD A VITAL DOCUMENT. IT WILL BE SHREDDED INTO 256-BIT FRAGMENTS, ENCRYPTED LOCALLY, AND STORED IN YOUR PRIVATE CLOUD.",
      "action": "CHOOSE A DOCUMENT",
      "icon": "📄",
    },
    {
      "title": "APPOINT YOUR GUARDIANS",
      "desc": "SELECT THE PEOPLE YOU TRUST. THEY WILL ONLY RECEIVE ACCESS IF YOUR HEARTBEAT STOPS PULSING.",
      "action": "ADD A NOMINEE",
      "icon": "👥",
    },
    {
      "title": "THE DEAD MAN'S SWITCH",
      "desc": "SET YOUR CHECK-IN FREQUENCY. IF YOU DON'T CHECK IN, WE'LL REACH OUT. IF THERE'S NO RESPONSE, YOUR LEGACY IS RELEASED.",
      "action": "SET HEARTBEAT",
      "icon": "💓",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 64),
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
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.01),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Text(_steps[index]['icon']!, style: const TextStyle(fontSize: 48)),
                            ),
                            const SizedBox(height: 56),
                            Text(
                              _steps[index]['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _steps[index]['desc']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, height: 1.8, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 64),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentStep < _steps.length - 1) {
                              _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeOutQuart);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            _steps[_currentStep]['action']!,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("SKIP PROTOCOL FOR NOW", style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
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
    final isActive = _currentStep == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: 4,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accentColor : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
