part of 'admin_dashboard_screen.dart';

extension _AdminDashboardCreateRoomSheet on _AdminDashboardHome {
  void _showCreateRoomSheet(
    BuildContext context,
    AdminRoomController controller,
  ) {
    CreateRoomDialog.show(context, controller);
  }
}
