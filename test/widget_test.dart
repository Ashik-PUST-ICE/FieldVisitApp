// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:field_visit_app/data/models/role_permission_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the Role & Permissions parsers.
///
/// Bug 1: `/settings/roles/list` returns `select('id','title')`, so reading a
/// `name` key produced "Unnamed role" for every entry.
///
/// Bug 2: `/settings/permissions/list` returns a NESTED tree
/// (`[{name, groups:[{name, permissions:[...]}]}]`), but the old screen parsed
/// it as a flat list, so the checklist came back empty.
void main() {
  group('parseRoles', () {
    test('falls back to the `title` key used by /roles/list', () {
      final roles = parseRoles([
        {'id': 1, 'title': 'Field Supervisor'},
        {'id': 2, 'title': 'Area Manager'},
      ]);

      expect(roles.map((r) => r.name), ['Field Supervisor', 'Area Manager']);
      expect(roles.every((r) => r.name != 'Unnamed role'), isTrue);
    });

    test('prefers `name` when present', () {
      final roles = parseRoles([
        {'id': 3, 'name': 'Admin', 'title': 'ignored'},
      ]);
      expect(roles.single.name, 'Admin');
    });

    test('unwraps the {data: {data: [...]}} envelope', () {
      final roles = parseRoles({
        'data': {
          'data': [
            {'id': 1, 'name': 'Nested Role'},
          ],
        },
      });
      expect(roles.single.name, 'Nested Role');
    });

    test('reads the status label into isActive', () {
      final roles = parseRoles([
        {'id': 1, 'name': 'Active One', 'status': 'Active'},
        {'id': 2, 'name': 'Inactive One', 'status': 'Inactive'},
      ]);
      expect(roles[0].isActive, isTrue);
      expect(roles[1].isActive, isFalse);
    });

    test('skips entries without a usable id', () {
      final roles = parseRoles([
        {'name': 'No Id'},
        {'id': null, 'name': 'Null Id'},
        {'id': 7, 'name': 'Good'},
      ]);
      expect(roles.map((r) => r.name), ['Good']);
    });
  });

  group('parsePermissionTree', () {
    test('flattens the nested category/group/permission tree', () {
      final items = parsePermissionTree([
        {
          'name': 'templates',
          'groups': [
            {
              'name': 'whatsapp',
              'permissions': [
                {
                  'id': 10,
                  'title': 'Send OTP',
                  'name': 'templates.otp.send',
                  'group': 'templates-whatsapp'
                },
                {
                  'id': 11,
                  'title': 'Send Invoice',
                  'name': 'templates.invoice.send',
                  'group': 'templates-whatsapp'
                },
              ],
            },
          ],
        },
      ]);

      expect(items.length, 2);
      expect(items.first.title, 'Send OTP');
      expect(items.first.category, 'templates');
      expect(items.first.group, 'whatsapp');
    });

    test('handles multiple categories and groups', () {
      final items = parsePermissionTree([
        {
          'name': 'templates',
          'groups': [
            {
              'name': 'sms',
              'permissions': [
                {'id': 1, 'title': 'A'},
              ],
            },
          ],
        },
        {
          'name': 'configurations',
          'groups': [
            {
              'name': 'email',
              'permissions': [
                {'id': 2, 'title': 'B'},
              ],
            },
          ],
        },
      ]);

      expect(items.length, 2);
      expect(items.map((p) => p.category).toSet(),
          {'templates', 'configurations'});
    });

    test('returns empty for malformed payloads instead of throwing', () {
      expect(parsePermissionTree(null), isEmpty);
      expect(parsePermissionTree(<String, dynamic>{}), isEmpty);
      expect(parsePermissionTree([1, 2, 3]), isEmpty);
      expect(
          parsePermissionTree([
            {'name': 'x'}
          ]),
          isEmpty);
      expect(
          parsePermissionTree([
            {'groups': 'not-a-list'}
          ]),
          isEmpty);
    });

    test('skips permissions with no id but keeps titled ones', () {
      final items = parsePermissionTree([
        {
          'name': 'cat',
          'groups': [
            {
              'name': 'grp',
              'permissions': [
                {'title': 'No Id'},
                {'id': 5, 'title': 'Has Id'},
              ],
            },
          ],
        },
      ]);
      expect(items.map((p) => p.id), [5]);
    });
  });

  group('parseAssignedPermissionIds', () {
    test('parses a list of bare ids', () {
      expect(parseAssignedPermissionIds([1, 2, '3']), {1, 2, 3});
    });

    test('parses a list of objects', () {
      expect(
          parseAssignedPermissionIds([
            {'id': 4},
            {'id': 5},
          ]),
          {4, 5});
    });

    test('ignores titles (the default RoleResource shape)', () {
      expect(parseAssignedPermissionIds(['Send OTP', 'Send Invoice']), isEmpty);
    });

    test('returns empty for null', () {
      expect(parseAssignedPermissionIds(null), isEmpty);
    });
  });

  group('RoleItem permission count', () {
    test('counts the permissions array when present', () {
      final role = RoleItem.fromJson({
        'id': 1,
        'name': 'Admin',
        'permissions': ['a', 'b', 'c'],
      });
      expect(role.permissionCount, 3);
    });

    test('defaults to zero', () {
      final role = RoleItem.fromJson({'id': 1, 'name': 'Admin'});
      expect(role.permissionCount, 0);
    });
  });
}
