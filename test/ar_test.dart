import 'dart:math';

import 'package:arweave/utils.dart' as utils;
import 'package:test/test.dart';

void main() {
  group('AR:', () {
    group('format winston as AR:', () {
      test('smaller than one AR', () {
        expect(
          utils.winstonToAr(BigInt.from(1)),
          equals('0.000000000001'),
        );
        expect(
          utils.winstonToAr(BigInt.from(111)),
          equals('0.000000000111'),
        );

        expect(
          utils.winstonToAr(BigInt.from(pow(10, 11))),
          equals('0.1'),
        );
        expect(
          utils.winstonToAr(BigInt.from(pow(10, 11) + 1)),
          equals('0.100000000001'),
        );
      });

      test('at least one AR', () {
        expect(
          utils.winstonToAr(BigInt.from(pow(10, 12))),
          equals('1'),
        );
        expect(
          utils.winstonToAr(BigInt.from(pow(10, 12) + pow(10, 11))),
          equals('1.1'),
        );

        expect(
          utils.winstonToAr(BigInt.from(pow(10, 13))),
          equals('10'),
        );
        expect(
          utils.winstonToAr(BigInt.from(pow(10, 13) + pow(10, 9))),
          equals('10.001'),
        );
      });
    });
  });
}
