// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_plivo/otel_plivo.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(serviceName: 'otel_plivo-test');
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('messages.create records uuid + units + charge', () async {
    await tracedPlivo<String>(
      operation: 'messages.create',
      invoke: () async => const PlivoCallResult(
        value: 'ok',
        result: PlivoResult(
          product: 'sms',
          messageUuid: 'm_1',
          messageType: 'sms',
          messageStatus: 'queued',
          units: 1,
          totalCharge: 8500,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('plivo messages.create')!);
    expect(a['plivo.message.uuid'], 'm_1');
    expect(a['plivo.message.units'], 1);
  });

  test('undelivered message sets span error', () async {
    await tracedPlivo<String>(
      operation: 'messages.create',
      invoke: () async => const PlivoCallResult(
        value: 'ok',
        result: PlivoResult(messageStatus: 'undelivered'),
      ),
    );
    expect(
      spans.findSpanByName('plivo messages.create')!.status,
      SpanStatusCode.Error,
    );
  });

  test('whatsapp template name recorded', () async {
    await tracedPlivo<String>(
      operation: 'whatsapp.send',
      invoke: () async => const PlivoCallResult(
        value: 'ok',
        result: PlivoResult(
          product: 'whatsapp',
          messageType: 'whatsapp',
          whatsappTemplateName: 'order_update_v2',
          whatsappTemplateNamespace: 'abcd_1234',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('plivo whatsapp.send')!);
    expect(a['plivo.whatsapp.template.name'], 'order_update_v2');
  });

  test('suppression skips spans', () async {
    await runWithoutPlivoInstrumentationAsync(() async {
      await tracedPlivo<String>(
        operation: 'numbers.list',
        invoke: () async => const PlivoCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('plivo '), isEmpty);
  });
}
