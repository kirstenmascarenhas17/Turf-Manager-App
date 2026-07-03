import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; 

void main() {
  runApp(const TurfManagerApp());
}

class TurfManagerApp extends StatelessWidget {
  const TurfManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turf Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.red,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.red,
          elevation: 0,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.red,
        ),
      ),
      // App now boots into the Vault Checker first!
      home: const AuthWrapper(), 
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkVault();
  }

  Future<void> _checkVault() async {
    // 1. Open the vault
    final prefs = await SharedPreferences.getInstance();
    
    // 2. Look for the token
    final token = prefs.getString('jwt_token');

    // Add a tiny delay just so you can see the loading animation!
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      if (token != null) {
        print('Vault Check: Token found! Bypassing login.');
        // Token exists -> Go straight to the Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TurfDashboardScreen()),
        );
      } else {
        print('Vault Check: Vault empty. Routing to login.');
        // No token -> Go to Login Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    // Use the exact IP address from your hotspot
    final url = Uri.parse('http://10.73.60.1:8000/login'); 

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Unpack the JSON data sent from Python
        final responseData = jsonDecode(response.body);
        
        // Extract the VIP wristband (JWT)
        final token = responseData['access_token'];
        
        // Open the device's vault and save the token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        
        print('Success! Token saved securely on the device.');

        // Push to the dashboard
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TurfDashboardScreen(),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Failed: Invalid credentials'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network Error: Could not connect to server.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turf Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.sports_soccer,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Player Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.red),
                ),
              ),
              const SizedBox(height: 20),
              
              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.red),
                ),
              ),
              const SizedBox(height: 40),
              
              // Login Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _handleLogin,
                child: const Text(
                  'LOGIN',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TurfDashboardScreen extends StatefulWidget {
  const TurfDashboardScreen({super.key});

  @override
  State<TurfDashboardScreen> createState() => _TurfDashboardScreenState();
}

class _TurfDashboardScreenState extends State<TurfDashboardScreen> {
  String _welcomeMessage = "Loading pitch data...";
  bool _isLoading = true;
  List<dynamic> _matches = []; 
  bool _showSquadOnly = false; // Tracks which filter is active

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      _handleLogout(context);
      return;
    }
    // NEW: Attach the filter to your existing dashboard URL!
    final urlString = _showSquadOnly 
        ? 'http://10.73.60.1:8000/me/dashboard?filter=squad'
        : 'http://10.73.60.1:8000/me/dashboard';

    final url = Uri.parse('http://10.73.60.1:8000/me/dashboard');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _welcomeMessage = data['message'];
          _matches = data['upcoming_matches']; 
          _isLoading = false;
        });
      } else {
        setState(() {
          _welcomeMessage = "Session expired. Please log in again.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _welcomeMessage = "Network error. Cannot reach the pitch.";
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pitch Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. The Welcome Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.sports_soccer, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _welcomeMessage,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // 2. The Title for the List
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Upcoming Matches',
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                // ... inside your Column in DashboardScreen ...
                const Text('Upcoming Matches', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // --- NEW DASHBOARD FILTER TOGGLE ---
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _showSquadOnly = false);
                            _fetchDashboardData(); // Reload the data
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_showSquadOnly ? Colors.red : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'GLOBAL',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_showSquadOnly ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _showSquadOnly = true);
                            _fetchDashboardData(); // Reload the data
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _showSquadOnly ? Colors.red : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'MY SQUAD',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _showSquadOnly ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. The Dynamic Scrollable List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final match = _matches[index];
                      return Card(
                        color: const Color(0xFF1E1E1E), 
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.red, width: 1), 
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading: const Icon(Icons.stadium, color: Colors.red, size: 36),
                          title: Text(
                            match['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${match['time']} • ${match['location']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.red),
                          
                          // --- ADD THIS NEW ONTAP BEHAVIOR ---
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MatchDetailsScreen(match: match),
                              ),
                            );
                          },       
                          
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      
      // --- THE FAB IS SAFELY ATTACHED HERE ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () async {
          // Open the Create Match screen
          final bool? matchCreated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateMatchScreen()),
          );
          
          // If a match was successfully created, refresh the dashboard!
          if (matchCreated == true) {
            setState(() => _isLoading = true);
            _fetchDashboardData();
          }
        },
      ),
    );
  }
}

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeDisplayController = TextEditingController(); // Only for showing the friendly text
  
  DateTime? _selectedDateTime; // The secret variable that holds the raw data
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _timeDisplayController.dispose();
    super.dispose();
  }

  // --- NEW: THE CALENDAR & TIME PICKER LOGIC ---
  Future<void> _pickDateTime() async {
    // 1. Show the Calendar
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Don't let them book in the past!
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.red,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return; // They clicked cancel

    // 2. Show the Clock
    if (!mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.red,
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    // 3. Combine them and format
    setState(() {
      _selectedDateTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
      
      // Pad single digits with zeroes (e.g., "9" becomes "09")
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      
      // Update the visual text field
      _timeDisplayController.text = "$day/$month/${date.year} $hour:$minute";
    });
  }

  Future<void> _submitMatch() async {
    if (_selectedDateTime == null || _titleController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return;

    final url = Uri.parse('http://10.73.60.1:8000/matches/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': _titleController.text,
          // Convert the true DateTime to the strict ISO string for Python!
          'date_time': _selectedDateTime!.toIso8601String(), 
          'turf_details': _locationController.text,
          'squad_id': 1 
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) Navigator.pop(context, true); 
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to schedule match'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network Error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Match', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.edit_calendar, size: 80, color: Colors.red),
            const SizedBox(height: 30),
            
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Match Title (e.g. Saturday 5v5)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.title, color: Colors.red),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Turf Location',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.stadium, color: Colors.red),
              ),
            ),
            const SizedBox(height: 20),
            
            // --- NEW: READ-ONLY FIELD THAT OPENS THE PICKER ---
            TextField(
              controller: _timeDisplayController,
              readOnly: true, // Prevents manual typing
              onTap: _pickDateTime, // Opens the native popup
              decoration: InputDecoration(
                labelText: 'Select Date & Time',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.access_time, color: Colors.red),
              ),
            ),
            const SizedBox(height: 40),
            
            // --- 1. PRIMARY ACTION: Schedule Match ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Keep your existing schedule match logic here
              },
              child: const Text('SCHEDULE MATCH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 16), // <-- THE FIX: 16 pixels of breathing room

            // --- 2. SECONDARY ACTION: Create a Squad (Tinted Premium Style) ---
            ElevatedButton.icon(
              icon: const Icon(Icons.group_add, size: 24, color: Colors.red), // Red icon
              label: const Text('Create a Squad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)), // Red text
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.15), // Subtle red tint for the background
                foregroundColor: Colors.red, // The splash ripple effect color
                elevation: 0, // Removes the drop shadow for a sleek, flat look
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateSquadScreen()),
                );
              },
            ),

            const SizedBox(height: 12), // <-- THE FIX: 12 pixels of breathing room

            // --- 3. TERTIARY ACTION: Join a Squad ---
            ElevatedButton.icon(
              icon: const Icon(Icons.group, size: 24),
              label: const Text('Join a Squad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.red, width: 2), // Outlined to show it's an alternative action
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JoinSquadScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MatchDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> match;

  const MatchDetailsScreen({super.key, required this.match});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  bool _isProcessing = false; // Renamed from _isJoining to handle both actions
  bool _isLoadingRoster = true;
  bool _isJoined = false; // Tracks if the user is on the roster
  List<dynamic> _roster = [];
  int _playerCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchRoster();
  }

  Future<void> _fetchRoster() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return;

    final url = Uri.parse('http://10.73.60.1:8000/matches/${widget.match['id']}/roster');

    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _roster = data['players'];
            _playerCount = data['player_count'];
            _isJoined = data['is_joined'] ?? false; // Read the new backend flag!
            _isLoadingRoster = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRoster = false);
    }
  }

  Future<void> _joinMatch() async {
    setState(() => _isProcessing = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    final url = Uri.parse('http://10.73.60.1:8000/rsvps/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'match_id': widget.match['id'], 'status': 'going'}),
      );

      if (mounted && (response.statusCode == 200 || response.statusCode == 201)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined!'), backgroundColor: Colors.green));
        _fetchRoster(); 
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- NEW: LEAVE MATCH FUNCTION ---
  Future<void> _leaveMatch() async {
    setState(() => _isProcessing = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    final url = Uri.parse('http://10.73.60.1:8000/matches/${widget.match['id']}/leave');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted && response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left the match.'), backgroundColor: Colors.orange));
        _fetchRoster(); // Refresh to remove your name
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.stadium, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  widget.match['title'],
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                          const SizedBox(width: 10),
                          Text(widget.match['time'], style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(widget.match['location'], style: const TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // --- DYNAMIC BUTTON LOGIC ---
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isJoined ? Colors.transparent : Colors.red,
                    foregroundColor: _isJoined ? Colors.red : Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: _isJoined ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                    ),
                  ),
                  onPressed: _isProcessing ? null : (_isJoined ? _leaveMatch : _joinMatch),
                  child: _isProcessing
                      ? CircularProgressIndicator(color: _isJoined ? Colors.red : Colors.white)
                      : Text(
                          _isJoined ? 'LEAVE SQUAD' : 'JOIN SQUAD', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.grey, thickness: 0.5),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Roster', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text('$_playerCount Players', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoadingRoster
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : _roster.isEmpty
                    ? const Center(child: Text('No players yet. Be the first!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _roster.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red,
                                child: Text(_roster[index][0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(_roster[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}


class CreateSquadScreen extends StatefulWidget {
  const CreateSquadScreen({super.key});

  @override
  State<CreateSquadScreen> createState() => _CreateSquadScreenState();
}

class _CreateSquadScreenState extends State<CreateSquadScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String? _generatedCode;

  Future<void> _createSquad() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a squad name'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('http://10.73.60.1:8000/squads/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': _nameController.text.trim()}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _generatedCode = data['invite_code']; // The backend hands us the 6-digit code!
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create squad'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network Error'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forge a Squad', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.shield, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            
            // 1. THE INPUT FORM (Hidden if code is already generated)
            if (_generatedCode == null) ...[
              const Text(
                'Give your squad a legendary name.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Squad Name (e.g. Weekend Warriors)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _createSquad,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CREATE SQUAD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],

            // 2. THE SUCCESS SCREEN (Shows the Invite Code)
            if (_generatedCode != null) ...[
              const Text(
                'Squad Created Successfully!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Column(
                  children: [
                    const Text('YOUR INVITE CODE', style: TextStyle(color: Colors.grey, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    Text(
                      _generatedCode!,
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, color: Colors.red),
                label: const Text('COPY TO CLIPBOARD', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 2),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generatedCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied! Send it to your friends.'), backgroundColor: Colors.green),
                  );
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class JoinSquadScreen extends StatefulWidget {
  const JoinSquadScreen({super.key});

  @override
  State<JoinSquadScreen> createState() => _JoinSquadScreenState();
}

class _JoinSquadScreenState extends State<JoinSquadScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinSquad() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite codes must be exactly 6 characters'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse('http://10.73.60.1:8000/squads/join');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'invite_code': code}),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Send them back to the dashboard on success
        } else if (response.statusCode == 404) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid code. Squad not found!'), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to join squad'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network Error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a Squad', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // --- THE FIX: Wrap the body in a SingleChildScrollView ---
      body: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.vpn_key, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Enter the 6-digit invite code provided by your squad captain.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: "", // Hides the default max length counter text
                  hintText: 'U Q Z R 4 E',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.3)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _joinSquad,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SUBMIT CODE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}