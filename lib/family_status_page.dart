import 'package:flutter/material.dart';
import 'services/family_member_service.dart';
import 'models/family_member.dart';
import 'services/database_service.dart';
import 'report_page.dart';
import 'pages/daily_tasks_page.dart';

class FamilyStatusPage extends StatefulWidget {
  const FamilyStatusPage({super.key});

  @override
  State<FamilyStatusPage> createState() => _FamilyStatusPageState();
}

class _FamilyStatusPageState extends State<FamilyStatusPage> {
  final FamilyMemberService _familyService = FamilyMemberService();
  bool _isLoading = false;
  String? _error;
  List<FamilyMember> _familyMembers = [];
  bool _isDisposed = false;
  final int currentUserId = 11;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    DatabaseService.instance.close();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _initializeData() async {
    try {
      await _testConnection();
      await _loadFamilyMembers();
    } catch (e) {
      print('Initialization error: $e');
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _error = 'Failed to initialize: $e';
        });
      }
    }
  }

  Future<void> _testConnection() async {
    try {
      await _familyService.testDatabaseConnection();
    } catch (e) {
      print('Connection test failed: $e');
      throw Exception('Database connection failed: $e');
    }
  }

  Future<void> _loadFamilyMembers() async {
    if (!mounted) return;

    _safeSetState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await DatabaseService.instance.close();

      int retryCount = 0;
      List<FamilyMember> members = [];

      while (retryCount < 3) {
        try {
          members = await _familyService.getFamilyMembers(currentUserId);
          break;
        } catch (e) {
          print('Attempt ${retryCount + 1} failed: $e');
          retryCount++;
          if (retryCount >= 3) rethrow;
          await Future.delayed(Duration(seconds: 2 * retryCount));
          await DatabaseService.instance.close();
        }
      }

      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _familyMembers = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading family members: $e');
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _error = 'Failed to load family members';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    await _loadFamilyMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFamilyMembers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_familyMembers.isEmpty) {
      return const Center(
        child: Text('No family members found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _familyMembers.length,
      itemBuilder: (context, index) {
        final member = _familyMembers[index];
        return _buildFamilyMemberCard(
          name: member.name,
          relation: member.relation,
          status: member.status,
          lastUpdate: member.lastUpdate,
          color: member.statusColor,
          imageUrl: member.imageUrl,
          email: member.email,
          memberId: member.id,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              const Text(
                'Family Status',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Track your family members\' health status',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberCard({
    required String name,
    required String relation,
    required String status,
    required String lastUpdate,
    required Color color,
    required String imageUrl,
    required String email,
    required int memberId,
  }) {
    return Dismissible(
      key: Key(memberId.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Remove Family Member'),
              content: Text(
                  'Are you sure you want to remove $name from your family members?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Remove',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          await _familyService.removeFamilyMember(currentUserId, memberId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name removed from family members')),
          );
          _loadFamilyMembers();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove family member: $e')),
          );
        }
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _showFamilyMemberReport(memberId, name),
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildAvatar(imageUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        relation,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.calendar_today,
                              color: Colors.blue[400]),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DailyTasksPage(
                                  patientId: memberId,
                                  patientName: name,
                                ),
                              ),
                            );
                          },
                          tooltip: 'View Calendar',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Colors.red[400]),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Remove Family Member'),
                                content: Text(
                                    'Are you sure you want to remove $name from your family members?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      'Remove',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await _familyService.removeFamilyMember(
                                    currentUserId, memberId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '$name removed from family members')),
                                );
                                _loadFamilyMembers();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to remove family member: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String imageUrl) {
    final Widget image =
        imageUrl.startsWith('http') || imageUrl.startsWith('https')
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person);
                },
              )
            : Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person);
                },
              );

    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey[200],
      child: ClipOval(
        child: SizedBox(
          width: 60,
          height: 60,
          child: image,
        ),
      ),
    );
  }

  void _showFamilyMemberReport(int memberId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(
          patientId: memberId,
          patientName: name,
        ),
      ),
    );
  }
}
