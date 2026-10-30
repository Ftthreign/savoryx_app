import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Clean Architecture Boundaries Lint Test', () {
    test('Domain layer must be pure Dart without data or platform imports', () {
      final featuresDir = Directory('lib/features');
      expect(
        featuresDir.existsSync(),
        isTrue,
        reason: 'lib/features directory must exist',
      );

      final domainFiles = <File>[];
      for (final entity in featuresDir.listSync(recursive: true)) {
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            entity.path.contains('${Platform.pathSeparator}domain${Platform.pathSeparator}')) {
          domainFiles.add(entity);
        }
      }

      expect(
        domainFiles.isNotEmpty,
        isTrue,
        reason: 'At least one domain entity file must exist to be verified',
      );

      final forbiddenSubstrings = <String>[
        '/data/',
        '/presentation/',
        'package:flutter/material.dart',
        'package:flutter/cupertino.dart',
        'package:flutter/widgets.dart',
        'package:dio/',
        'package:drift/',
        'package:sqflite/',
        'package:http/',
      ];

      final violations = <String>[];

      for (final file in domainFiles) {
        final lines = file.readAsLinesSync();
        final relativePath = file.path.replaceAll('\\', '/');

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('import ')) {
            for (final forbidden in forbiddenSubstrings) {
              if (trimmed.contains(forbidden)) {
                violations.add(
                  '$relativePath: forbidden import "$trimmed" contains "$forbidden"',
                );
              }
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Domain layer must remain 100% pure Dart without platform or outer layer dependencies:\n${violations.join('\n')}',
      );
    });
  });
}
