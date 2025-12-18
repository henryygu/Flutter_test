import 'package:flutter_test/flutter_test.dart';
import 'package:orgflow/org_node.dart';
import 'package:orgflow/node_manager.dart';

void main() {
  test('OrgNode state change is logged', () {
    final node = OrgNode();
    final manager = NodeManager();

    expect(node.todoState, 'TODO');

    manager.setNodeState(node, 'DONE');
    expect(node.todoState, 'DONE');
    expect(node.history.isNotEmpty, true);
    expect(node.history.last.message.contains('DONE'), true);
  });

  test('OrgNode clocking', () {
    final node = OrgNode();
    final manager = NodeManager();

    expect(manager.isClockedIn(node), false);

    manager.clockIn(node);
    expect(manager.isClockedIn(node), true);
    expect(node.clockLogs.length, 1);

    manager.clockOut(node);
    expect(manager.isClockedIn(node), false);
    expect(node.clockLogs.first.end, isNotNull);
  });
}
