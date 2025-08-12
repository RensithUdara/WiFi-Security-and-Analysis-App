import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_manager.dart';
import '../auth/login_screen.dart';
import 'history_detail_screen.dart';

class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _auth = FirebaseAuth.instance;

  // A key to allow us to manually refresh the StreamBuilder
  Key _historyListKey = UniqueKey();

  void _refreshHistory() {
    setState(() {
      _historyListKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.baseColor(context),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(NeumorphicTheme.accentColor(context)),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return _buildLoggedInView(snapshot.data!);
          }
          return _buildLoggedOutView();
        },
      ),
    );
  }

  Widget _buildLoggedOutView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: NeumorphicTheme.baseColor(context),
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Profile',
              style: TextStyle(
                color: NeumorphicTheme.defaultTextColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NeumorphicTheme.baseColor(context),
                    NeumorphicTheme.baseColor(context).withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverFillRemaining(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Neumorphic(
                  style: NeumorphicStyle(
                    depth: 8,
                    boxShape: NeumorphicBoxShape.circle(),
                    color: NeumorphicTheme.baseColor(context),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(32),
                    child: Icon(
                      Icons.account_circle_outlined,
                      size: 80,
                      color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.4),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Welcome to WiFi Security',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: NeumorphicTheme.defaultTextColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Sign in to save your scan history, track network security alerts, and access advanced features.',
                  style: TextStyle(
                    fontSize: 16,
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Neumorphic(
                  style: NeumorphicStyle(
                    depth: 4,
                    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(30)),
                    color: NeumorphicTheme.accentColor(context),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'SIGN IN',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    // Add sign up navigation if needed
                  },
                  child: Text(
                    'Don\'t have an account? Sign up',
                    style: TextStyle(
                      color: NeumorphicTheme.accentColor(context),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInView(User user) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          floating: false,
          pinned: true,
          backgroundColor: NeumorphicTheme.baseColor(context),
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildProfileHeader(user),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Neumorphic(
                style: NeumorphicStyle(
                  shape: NeumorphicShape.flat,
                  boxShape: NeumorphicBoxShape.circle(),
                  depth: 2,
                ),
                child: IconButton(
                  onPressed: _refreshHistory,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: NeumorphicTheme.defaultTextColor(context),
                  ),
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: _buildQuickActions(),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: _buildHistorySection(),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NeumorphicTheme.baseColor(context),
            NeumorphicTheme.baseColor(context).withOpacity(0.9),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(height: 40),
              Neumorphic(
                style: NeumorphicStyle(
                  shape: NeumorphicShape.flat,
                  boxShape: NeumorphicBoxShape.circle(),
                  depth: 8,
                  color: NeumorphicTheme.baseColor(context),
                ),
                child: Container(
                  padding: EdgeInsets.all(4),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: NeumorphicTheme.accentColor(context).withOpacity(0.1),
                    backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    child: user.photoURL == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: NeumorphicTheme.accentColor(context),
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                user.displayName ?? 'WiFi Security User',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NeumorphicTheme.defaultTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                user.email ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusBadge(
                    icon: Icons.verified_user_rounded,
                    label: 'Verified',
                    color: Colors.green,
                  ),
                  SizedBox(width: 16),
                  _buildStatusBadge(
                    icon: Icons.security_rounded,
                    label: 'Secure',
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: NeumorphicTheme.defaultTextColor(context),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  subtitle: 'App preferences',
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to settings
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Logout safely',
                  color: Colors.red,
                  onTap: () async {
                    await _auth.signOut();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 3,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
        color: NeumorphicTheme.baseColor(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NeumorphicTheme.defaultTextColor(context),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NeumorphicTheme.defaultTextColor(context),
                  ),
                ),
                Consumer<ThemeManager>(
                  builder: (context, themeManager, child) => Neumorphic(
                    style: NeumorphicStyle(
                      depth: -2,
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            themeManager.themeMode == ThemeMode.dark 
                              ? Icons.dark_mode_rounded 
                              : Icons.light_mode_rounded,
                            size: 16,
                            color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.7),
                          ),
                          SizedBox(width: 8),
                          NeumorphicSwitch(
                            value: themeManager.themeMode == ThemeMode.dark,
                            onChanged: (value) {
                              themeManager.toggleTheme(value);
                            },
                            style: NeumorphicSwitchStyle(
                              thumbColor: NeumorphicTheme.accentColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return SizedBox.shrink();

    final speedTestStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('speedTestHistory')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      key: _historyListKey,
      stream: speedTestStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(NeumorphicTheme.accentColor(context)),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyHistory();
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildHistoryItem(data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'No activity yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your WiFi scans and speed tests will appear here',
            style: TextStyle(
              fontSize: 14,
              color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> data) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (data['type']) {
      case 'speedTest':
        icon = Icons.speed_rounded;
        color = Colors.blue;
        title = 'Speed Test';
        subtitle = '${data['downloadSpeed']?.toStringAsFixed(1) ?? 'N/A'} Mbps';
        break;
      case 'wifiScan':
        icon = Icons.wifi_find_rounded;
        color = Colors.green;
        title = 'WiFi Scan';
        subtitle = '${data['networksFound'] ?? 0} networks found';
        break;
      default:
        icon = Icons.analytics_rounded;
        color = Colors.purple;
        title = 'Activity';
        subtitle = 'Recorded';
    }

    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null 
        ? DateFormat('MMM dd, HH:mm').format(timestamp.toDate())
        : 'Unknown time';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 2,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
          color: NeumorphicTheme.baseColor(context),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryDetailScreen(data: data),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: NeumorphicTheme.defaultTextColor(context),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: NeumorphicTheme.defaultTextColor(context).withOpacity(0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
