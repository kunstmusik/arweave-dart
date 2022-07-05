@TestOn('browser')
@JS()
library tagparser;

import 'dart:convert';
import 'dart:typed_data';

import 'package:arweave/arweave.dart';
import 'package:arweave/src/crypto/crypto.dart';
import 'package:arweave/src/utils/bundle_tag_parser.dart';
import 'package:arweave/utils.dart';
import 'package:js/js.dart';
import 'package:test/test.dart';

import 'fixtures/test_wallet.dart';
import 'snapshots/data_bundle_test_snaphot.dart';
import 'utils.dart' show generateByteList;

// Implement deserializeTags from official Avro JS library to test Dart Native serialize
@JS()
@anonymous
class BundleTag {
  external String get name;
  external String get value;

  // Must have an unnamed factory constructor with named arguments.
  external factory BundleTag({
    String name,
    String value,
  });
}

class WrongTagBufferException implements Exception {}

@JS()
external List<BundleTag> deserializeTagsFromBuffer(var buffer);

List<Tag> deserializeTags({var buffer}) {
  try {
    final tags = deserializeTagsFromBuffer(buffer);
    final decodedTags = <Tag>[];
    for (var tag in tags) {
      decodedTags.add(Tag(
        encodeBytesToBase64(
            tag.name.split(',').map((e) => int.parse(e)).toList()),
        encodeBytesToBase64(
            tag.value.split(',').map((e) => int.parse(e)).toList()),
      ));
    }

    return decodedTags;
  } catch (e) {
    throw WrongTagBufferException();
  }
}

void main() async {
  group('DataItem:', () {
    test('create, sign, and verify data item', () async {
      final wallet = getTestWallet();
      final dataItem = DataItem.withBlobData(
          owner: await wallet.getOwner(),
          data: utf8.encode('HELLOWORLD_TEST_STRING') as Uint8List)
        ..addTag('MyTag', '0')
        ..addTag('OtherTag', 'Foo')
        ..addTag('MyTag', '1');

      await dataItem.sign(wallet);

      expect(await dataItem.verify(), isTrue);
    });

    test('confirm data item with wrong signaure fails verify', () async {
      final wallet = getTestWallet();
      final dataItem = DataItem.withBlobData(
          owner: await wallet.getOwner(),
          data: utf8.encode('HELLOWORLD_TEST_STRING') as Uint8List)
        ..addTag('MyTag', '0')
        ..addTag('OtherTag', 'Foo')
        ..addTag('MyTag', '1');

      await dataItem.sign(wallet);
      dataItem.addTag('MyTag', '2');

      expect(await dataItem.verify(), isFalse);
    });
  });

  test('check if avro serializes tags correctly', () {
    final buffer = serializeTags(tags: testTagsSnapshot);
    expect(buffer, equals(testTagsBufferSnapshot));
  });

  test('check if avro fails serialization when wrong data is given', () {
    final testTags = [
      Tag(encodeStringToBase64('wrong'), encodeStringToBase64('wrong'))
    ];
    final buffer = serializeTags(tags: testTags);

    expect(
      () => deserializeTags(buffer: [Uint8List.fromList(buffer), 0]),
      throwsException,
    );
  });

  test('check if avro deserializes tags correctly', () {
    final tags = deserializeTags(buffer: testTagsBufferSnapshot);
    expect(tags, equals(testTagsSnapshot));
  });

  test('create data bundle', () async {
    final wallet = getTestWallet();

    final dataItemOne = DataItem.withBlobData(
        owner: await wallet.getOwner(),
        data: utf8.encode('HELLOWORLD_TEST_STRING_1') as Uint8List)
      ..addTag('MyTag', '0')
      ..addTag('OtherTag', 'Foo')
      ..addTag('MyTag', '1');
    await dataItemOne.sign(wallet);
    final dataItemTwo = DataItem.withBlobData(
        owner: await wallet.getOwner(),
        data: utf8.encode('HELLOWORLD_TEST_STRING_2') as Uint8List)
      ..addTag('MyTag', '0')
      ..addTag('OtherTag', 'Foo')
      ..addTag('MyTag', '1');
    await dataItemTwo.sign(wallet);
    final items = [dataItemOne, dataItemTwo];
    final bundle = await DataBundle.fromDataItems(items: items);
    expect(bundle.blob, isNotEmpty);
    for (var dataItem in items) {
      expect(await dataItem.verify(), isTrue);
    }
  });

  test('create data bundle with large files', () async {
    final wallet = getTestWallet();
    final testData = generateByteList(5);
    print('Test Data Item Size: ${testData.lengthInBytes} Bytes ');
    expect(await deepHash([testData]), equals(testFileHash));
    final testStart = DateTime.now();
    final dataItemOne =
        DataItem.withBlobData(owner: await wallet.getOwner(), data: testData)
          ..addTag('MyTag', '0')
          ..addTag('OtherTag', 'Foo')
          ..addTag('MyTag', '1');
    await dataItemOne.sign(wallet);
    final dataItemTwo =
        DataItem.withBlobData(owner: await wallet.getOwner(), data: testData)
          ..addTag('MyTag', '0')
          ..addTag('OtherTag', 'Foo')
          ..addTag('MyTag', '1');
    await dataItemTwo.sign(wallet);
    final items = [dataItemOne, dataItemTwo];
    final bundle = await DataBundle.fromDataItems(items: items);
    expect(bundle.blob, isNotEmpty);

    print('Bundle Data Size: ${bundle.blob.lengthInBytes} Bytes ');

    print(
        'Time Elapsed to bundle ${(DateTime.now().difference(testStart)).inMilliseconds}ms');
    expect(testData.length < bundle.blob.length, isTrue);
    for (var dataItem in items) {
      expect(await dataItem.verify(), isTrue);
    }
  });
}
