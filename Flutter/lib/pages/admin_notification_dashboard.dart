import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../services/admin_notification_service.dart';

const Color kPrimary = Colors.green;
const Color kAccent = AppColors.primary;
const Color kCard = AppColors.surface;

class AdminNotificationDashboard extends StatefulWidget {
  const AdminNotificationDashboard({super.key});

  @override
  State<AdminNotificationDashboard> createState() =>
      _AdminNotificationDashboardState();
}

class _AdminNotificationDashboardState
    extends State<AdminNotificationDashboard> {
  final AdminNotificationService _adminService = AdminNotificationService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _selectedTargetType = 'logged_in_users';
  UserStats? _stats;
  List<UserSummary> _users = [];
  List<int> _selectedUserIds = [];
  bool _isLoading = false;

  final Map<String, String> _targetTypes = {
    'all_users_including_guests': 'Everyone (Including Visitors)',
    'guests_only': 'Visitors Only (Not Logged In)',
    'logged_in_users': 'Registered Users',
    'property_owners': 'Property Owners',
    'auction_owners': 'Active Auction Sellers',
    'bidders': 'Active Bidders',
    'verified_users': 'Verified Accounts',
    'unverified_users': 'Unverified Accounts',
    'specific': 'Selected Users',
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final response = await _adminService.getUserStats();
    if (response.success && response.data != null) {
      setState(() {
        _stats = response.data;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Failed to load stats')),
        );
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final filter = _selectedTargetType == 'all' ? null : _selectedTargetType;
    final response = await _adminService.getUsers(filter: filter);
    if (response.success && response.data != null) {
      setState(() {
        _users = response.data!;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Failed to load users')),
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and message')),
      );
      return;
    }

    if (_selectedTargetType == 'specific' && _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Send'),
        content: Text(
          'Send notification to ${_targetTypes[_selectedTargetType]}?${_selectedTargetType == 'specific' ? '\n\nSelected: ${_selectedUserIds.length} user(s)' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final response = await _adminService.sendNotification(
      targetType: _selectedTargetType,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      userIds: _selectedTargetType == 'specific' ? _selectedUserIds : null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data?.message ?? 'Notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedUserIds.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Failed to send notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Dashboard'),
        backgroundColor: kPrimary,
        foregroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading && _stats == null
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stats Cards
                  _buildStatsSection(),
                  const SizedBox(height: 24),

                  // Notification Composer
                  _buildComposerSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Users',
              _stats!.totalUsers.toString(),
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Property Owners',
              _stats!.propertyOwnersCount.toString(),
              Icons.home,
              Colors.orange,
            ),
            _buildStatCard(
              'Auction Owners',
              _stats!.auctionOwnersCount.toString(),
              Icons.gavel,
              Colors.purple,
            ),
            _buildStatCard(
              'Bidders',
              _stats!.biddersCount.toString(),
              Icons.attach_money,
              Colors.green,
            ),
            _buildStatCard(
              'Verified',
              _stats!.verifiedCount.toString(),
              Icons.verified,
              AppColors.primary,
            ),
            _buildStatCard(
              'Unverified',
              _stats!.unverifiedCount.toString(),
              Icons.pending,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComposerSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Compose Notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Target Type Selector
          const Text(
            'Select Recipients',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedTargetType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: _targetTypes.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTargetType = value!;
                _selectedUserIds.clear();
                if (value == 'specific') {
                  _loadUsers();
                }
              });
            },
          ),
          const SizedBox(height: 20),

          // User Selection (only for specific)
          if (_selectedTargetType == 'specific') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Users (${_selectedUserIds.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showUserSelectionDialog,
                  icon: const Icon(Icons.people),
                  label: const Text('Select'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedUserIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedUserIds.length} user(s) selected',
                  style: const TextStyle(color: kPrimary),
                ),
              ),
            const SizedBox(height: 20),
          ],

          // Title Input
          const Text(
            'Title',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Enter notification title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLength: 100,
          ),
          const SizedBox(height: 16),

          // Message Input
          const Text(
            'Message',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Enter notification message',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 4,
            maxLength: 500,
          ),
          const SizedBox(height: 24),

          // Send Button
          ElevatedButton(
            onPressed: _isLoading ? null : _sendNotification,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.surface,
                      ),
                    ),
                  )
                : const Text(
                    'Send Notification',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUserSelectionDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Users'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _users.isEmpty
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isSelected = _selectedUserIds.contains(
                      user.accountId,
                    );
                    return CheckboxListTile(
                      title: Text(user.fullName),
                      subtitle: Text(user.email),
                      value: isSelected,
                      activeColor: kPrimary,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedUserIds.add(user.accountId);
                          } else {
                            _selectedUserIds.remove(user.accountId);
                          }
                        });
                        // Rebuild dialog
                        Navigator.pop(context);
                        _showUserSelectionDialog();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
