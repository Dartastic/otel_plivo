// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_plivo/otel_plivo.dart';

/// Traces Plivo calls with OpenTelemetry.
///
/// `otel_plivo` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Plivo call in
/// [tracedPlivo]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'plivo-example');

  // Wraps a Plivo API call in a CLIENT span.
  final plivoId = await tracedPlivo<String>(
    operation: 'messages.create',
    invoke: () async {
      // Make the Plivo call here, then report what it returned.
      const id = 'plivo_8f3a2c';
      return const PlivoCallResult(
          value: id,
          result: PlivoResult(
              product: 'sms',
              authId: 'auth_8f3a2c',
              from: 'example',
              to: 'example',
              countryCode: 'example',
              messageUuid: 'messageuu_8f3a2c',
              messageType: 'sms',
              messageStatus: 'queued',
              totalRate: 1,
              totalCharge: 1,
              units: 1,
              callUuid: 'calluu_8f3a2c',
              callDirection: 'inbound',
              callStatus: 'queued',
              callDurationSec: 120,
              callBillDurationSec: 120,
              verifyId: 'verify_8f3a2c',
              verifyStatus: 'pending',
              verifyChannel: 'sms',
              whatsappTemplateName: 'example',
              whatsappTemplateNamespace: 'example',
              errorCode: 'example',
              errorMessage: 'example',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedPlivo messages.create returned $plivoId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutPlivoInstrumentationAsync.
  await runWithoutPlivoInstrumentationAsync(
    () => tracedPlivo<String>(
      operation: 'messages.create',
      invoke: () async {
        const id = 'plivo_8f3a2c';
        return const PlivoCallResult(
            value: id,
            result: PlivoResult(
                product: 'sms',
                authId: 'auth_8f3a2c',
                from: 'example',
                to: 'example',
                countryCode: 'example',
                messageUuid: 'messageuu_8f3a2c',
                messageType: 'sms',
                messageStatus: 'queued',
                totalRate: 1,
                totalCharge: 1,
                units: 1,
                callUuid: 'calluu_8f3a2c',
                callDirection: 'inbound',
                callStatus: 'queued',
                callDurationSec: 120,
                callBillDurationSec: 120,
                verifyId: 'verify_8f3a2c',
                verifyStatus: 'pending',
                verifyChannel: 'sms',
                whatsappTemplateName: 'example',
                whatsappTemplateNamespace: 'example',
                errorCode: 'example',
                errorMessage: 'example',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
