import 'package:flutter/material.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import 'folders_screen.dart'; 
import 'nominee_screen.dart'; 
import 'scan_document_screen.dart';
import 'profile_screen.dart';
import 'ai_will_drafter_screen.dart';

class SecureDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile; // Accept profile data directly

  const SecureDashboardScreen({Key? key, this.userProfile}) : super(key: key);

  @override
  _SecureDashboardScreenState createState() => _SecureDashboardScreenState();
}

class _SecureDashboardScreenState extends State<SecureDashboardScreen> {
  Map<String, dynamic>? userProfile;
  late int userId;

  @override
  void initState() {
    super.initState();
    // Use passed profile or default
    userProfile = widget.userProfile;
    // Extract User ID safely. If not found, default to 0 (which will show empty data)
    // Adjust based on actual API response structure. 
    // If userProfile is top level user object: userProfile['id']
    // If userProfile is wrapper: userProfile['user']['id']
    if (userProfile != null) {
      if (userProfile!.containsKey('id')) {
        userId = userProfile!['id'] is int ? userProfile!['id'] : int.tryParse(userProfile!['id'].toString()) ?? 0;
      } else if (userProfile!.containsKey('user') && userProfile!['user'] is Map) {
         userId = userProfile!['user']['id'] is int ? userProfile!['user']['id'] : int.tryParse(userProfile!['user']['id'].toString()) ?? 0;
      } else {
        userId = 0;
      }
    } else {
      userId = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine Display Name
    String userName = "User";
    if (userProfile != null) {
        userName = userProfile!['name'] ?? userProfile!['user']?['name'] ?? "User";
    }
    
    return Scaffold(
      extendBody: true, // Important for glass bottom bar
      backgroundColor: AppTheme.backgroundColor, // Use light background
      body: Container(
        decoration: const BoxDecoration(
          // Subtle Apple-like Mesh Gradient (Light Blue / White)
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF2F2F7), // System Gray 6 (Light)
              Color(0xFFE5E5EA), // System Gray 5 (Slightly darker for depth)
              Color(0xFFF2F2F7),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back,",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$userName's Vault", 
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.textPrimary, // Black text
                            letterSpacing: -0.5, // Apple style tightness
                          ),
                        ),
                      ],
                    ),
                    // Profile Icon in Glass (White frosted)
                    GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userProfile: userProfile)));
                      },
                      child: GlassCard(
                        borderRadius: BorderRadius.circular(50),
                        padding: const EdgeInsets.all(8),
                        blur: 20,
                        opacity: 0.6, // Higher opacity for visibility
                        color: Colors.white,
                        child: const Icon(Icons.person, color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassCard(
                  opacity: 0.6,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: const TextField(
                    style: TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey),
                      hintText: "Search encrypted files...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Quick Actions Grid
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(24),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      context,
                      "Secure Folders",
                      Icons.folder_shared_rounded,
                      Colors.blueAccent,
                      () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => FoldersScreen(userId: userId)));
                      },
                    ),
                    _buildActionCard(
                      context,
                      "Nominees",
                      Icons.people_alt_rounded,
                      Colors.purpleAccent,
                      () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => NomineeScreen(userId: userId)));
                      },
                    ),
                    _buildActionCard(
                      context,
                      "AI Will Drafter",
                      Icons.psychology_rounded,
                      Colors.cyan,
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AIWillDrafterScreen(userId: userId)));
                      },
                    ),
                    _buildActionCard(
                      context,
                      "Scan Document",
                      Icons.document_scanner_rounded,
                      Colors.orangeAccent,
                      () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanDocumentScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Glass Bottom Navigation Bar
      bottomNavigationBar: GlassCard(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 30), // Lifted up slightly
        borderRadius: BorderRadius.circular(30),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        opacity: 0.7, // Frosted White
        color: Colors.white.withOpacity(0.8), 
        blur: 30, // High blur
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.home_filled, color: AppTheme.primaryColor), onPressed: () {}),
            IconButton(icon: const Icon(Icons.upload_file, color: Colors.grey), onPressed: () {}),
            IconButton(icon: const Icon(Icons.settings, color: Colors.grey), onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userProfile: userProfile)));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        opacity: 0.65, // Distinct White Glass
        color: Colors.white,
        blur: 20,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Very light tint of the accent color
                shape: BoxShape.circle,
                // Removed heavy shadow for cleaner Apple look
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87, // Dark Text
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

