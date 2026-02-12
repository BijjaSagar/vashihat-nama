import 'package:flutter/material.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class NomineeScreen extends StatefulWidget {
  final int userId;
  const NomineeScreen({super.key, required this.userId});

  @override
  _NomineeScreenState createState() => _NomineeScreenState();
}

class _NomineeScreenState extends State<NomineeScreen> {
  List<dynamic> nominees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNominees();
  }

  Future<void> _loadNominees() async {
    try {
      final fetchedNominees = await ApiService().getNominees(widget.userId.toString());
      if (mounted) {
        setState(() {
          nominees = fetchedNominees;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading nominees: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _addNominee(String name, String relation, String contact) async {
    try {
      await ApiService().addNominee(widget.userId.toString(), name, relation, contact);
      _loadNominees(); // Refresh list
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nominee Added")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Trusted Nominees", 
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF2F2F7), // System Gray 6
              Color(0xFFE5E5EA), // System Gray 5
              Color(0xFFF2F2F7),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header / Info Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  opacity: 0.6,
                  blur: 20,
                  color: Colors.white,
                  borderColor: Colors.white.withOpacity(0.9),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Nominees will only gain access to your encrypted vault after your approval or the activation of the 'Legacy Protocol'.",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Nominee List
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : nominees.isEmpty 
                    ? Center(child: Text("No nominees added yet", style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: nominees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final nominee = nominees[index];
                          // Handling mock fields if backend doesn't return exactly these
                          String status = nominee['status'] ?? 'Pending'; 
                          String firstLetter = (nominee['name'] as String).isNotEmpty ? nominee['name'][0] : "?";

                          return GlassCard(
                            opacity: 0.6, // White Glass
                            blur: 15,
                            color: Colors.white,
                            borderColor: Colors.white.withOpacity(0.9),
                            padding: const EdgeInsets.all(16),
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  child: Text(
                                    firstLetter,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 20),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nominee['name'],
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: status == 'Verified' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: status == 'Verified' ? Colors.green : Colors.orange,
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: status == 'Verified' ? Colors.green : Colors.orange,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            nominee['relation'], 
                                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Edit Action
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final nameCtrl = TextEditingController();
          final relationCtrl = TextEditingController();
          final contactCtrl = TextEditingController();

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Add Nominee"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name", hintText: "Full Name")),
                   TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: "Relation", hintText: "e.g. Wife, Son")),
                   TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: "Contact", hintText: "Phone Number")),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty && relationCtrl.text.isNotEmpty) {
                      Navigator.pop(context);
                      _addNominee(nameCtrl.text, relationCtrl.text, contactCtrl.text);
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text("Add Nominee", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

