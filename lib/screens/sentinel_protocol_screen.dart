import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SentinelProtocolScreen extends StatefulWidget {
  const SentinelProtocolScreen({super.key});

  @override
  State<SentinelProtocolScreen> createState() => _SentinelProtocolScreenState();
}

class _SentinelProtocolScreenState extends State<SentinelProtocolScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<ProtocolStep> _steps = [
    ProtocolStep(
      title: "ZERO-TRUST INITIALIZATION",
      description: "WELCOME TO THE SENTINEL PROTOCOL. YOUR LEGACY IS NOW PROTECTED BY MULTI-LAYERED BIOMETRIC ENCRYPTION AND INSTITUTIONAL-GRADE SECURITY.",
      icon: Icons.shield_outlined,
      tag: "PHASE 01",
    ),
    ProtocolStep(
      title: "SECURE VAULT ARCHITECTURE",
      description: "DEPOSIT SENSITIVE DOCUMENTS, LEGAL WILLS, AND MEDICAL DIRECTIVES. EVERYTHING IS STORED WITH SSL PINNING AND ZERO-KNOWLEDGE PRINCIPLES.",
      icon: Icons.inventory_2_outlined,
      tag: "PHASE 02",
    ),
    ProtocolStep(
      title: "ACCESS HIERARCHY",
      description: "CONFIGURE YOUR NOMINEE NETWORK. GRANT CONDITIONAL ACCESS BASED ON TRUST PARAMETERS AND VERIFIED AUTHENTICATION TRIGGERS.",
      icon: Icons.account_tree_outlined,
      tag: "PHASE 03",
    ),
    ProtocolStep(
      title: "PULSE-BEAT MONITORING",
      description: "THE SYSTEM MONITORS YOUR ACTIVITY STATUS. IF THE PULSE CEASES, THE SENTINEL PROTOCOL AUTOMATICALLY INITIATES DATA TRANSFER TO YOUR NOMINEES.",
      icon: Icons.favorite_border_rounded,
      tag: "PHASE 04",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background subtle noise/gradient or just keep it ink black
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    AppTheme.accentColor.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _steps.length,
            itemBuilder: (context, index) {
              final step = _steps[index];
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Node
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        step.icon,
                        color: AppTheme.accentColor,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 64),
                    
                    // Tag
                    Text(
                      step.tag,
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Description
                    Text(
                      step.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.8,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Controls
          Positioned(
            bottom: 64,
            left: 40,
            right: 40,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      width: _currentIndex == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index 
                            ? AppTheme.accentColor 
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 48),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentIndex < _steps.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutQuart,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentIndex == _steps.length - 1 
                          ? AppTheme.accentColor 
                          : Colors.white.withOpacity(0.05),
                      foregroundColor: _currentIndex == _steps.length - 1 
                          ? Colors.black 
                          : Colors.white,
                      side: _currentIndex == _steps.length - 1 
                          ? null 
                          : BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Text(
                      _currentIndex == _steps.length - 1 
                          ? "INITIALIZE PROTOCOL" 
                          : "PROCEED",
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProtocolStep {
  final String title;
  final String description;
  final IconData icon;
  final String tag;

  ProtocolStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.tag,
  });
}
