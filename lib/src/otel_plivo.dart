// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_plivo_suppression.dart';

const _tracerName = 'dartastic_otel_libs_plivo';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class PlivoResult {
  const PlivoResult({
    this.product,
    this.authId,
    this.from,
    this.to,
    this.countryCode,
    this.messageUuid,
    this.messageType,
    this.messageStatus,
    this.totalRate,
    this.totalCharge,
    this.units,
    this.callUuid,
    this.callDirection,
    this.callStatus,
    this.callDurationSec,
    this.callBillDurationSec,
    this.verifyId,
    this.verifyStatus,
    this.verifyChannel,
    this.whatsappTemplateName,
    this.whatsappTemplateNamespace,
    this.errorCode,
    this.errorMessage,
    this.statusCode,
  });

  /// `sms`, `mms`, `whatsapp`, `voice`, `verify`, `numbers`,
  /// `applications`, `lookup`, `media`, `recording`, `messaging`,
  /// `conferences`.
  final String? product;

  /// Plivo auth id (MA... or M...).
  final String? authId;

  final String? from;
  final String? to;
  final String? countryCode;

  // ── Messaging ──────────────────────────────────────────────────
  final String? messageUuid;

  /// `sms`, `mms`, `whatsapp`.
  final String? messageType;

  /// `queued`, `sent`, `failed`, `delivered`, `undelivered`,
  /// `rejected`, `read`.
  final String? messageStatus;

  /// Per-message rate (USD string from API; we record as decimal cents
  /// when caller provides micro units).
  final int? totalRate;
  final int? totalCharge;
  final int? units;

  // ── Voice ──────────────────────────────────────────────────────
  final String? callUuid;

  /// `inbound`, `outbound`.
  final String? callDirection;

  /// `queued`, `ringing`, `in-progress`, `completed`, `busy`, `failed`,
  /// `no-answer`, `canceled`.
  final String? callStatus;

  final int? callDurationSec;
  final int? callBillDurationSec;

  // ── Verify ─────────────────────────────────────────────────────
  final String? verifyId;

  /// `pending`, `verified`, `expired`, `failed`, `cancelled`.
  final String? verifyStatus;

  /// `sms`, `voice`, `whatsapp`.
  final String? verifyChannel;

  // ── WhatsApp ──────────────────────────────────────────────────
  final String? whatsappTemplateName;
  final String? whatsappTemplateNamespace;

  /// Plivo numeric error code.
  final String? errorCode;
  final String? errorMessage;
  final int? statusCode;
}

class PlivoCallResult<T> {
  const PlivoCallResult({required this.value, this.result});
  final T value;
  final PlivoResult? result;
}

/// Wraps a Plivo API call in a CLIENT span. [operation] is one of
/// `messages.create`, `messages.list`, `messages.get`,
/// `messages.delete`, `whatsapp.send`, `whatsapp.template.create`,
/// `whatsapp.template.list`, `voice.calls.create`, `voice.calls.list`,
/// `voice.calls.get`, `voice.calls.update`, `voice.calls.hangup`,
/// `voice.calls.record`, `voice.calls.playMedia`, `voice.calls.transfer`,
/// `voice.conferences.create`, `voice.conferences.get`, `verify.create`,
/// `verify.validate`, `verify.list`, `lookup.numberFormat`,
/// `lookup.numberInsight`, `numbers.list`, `numbers.buy`,
/// `numbers.cancel`, `applications.list`, `applications.create`,
/// `media.upload`, `media.get`, `recordings.list`, `recordings.delete`.
Future<T> tracedPlivo<T>({
  required String operation,
  required Future<PlivoCallResult<T>> Function() invoke,
}) async {
  if (plivoInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'plivo',
    'rpc.method': operation,
    'plivo.operation': operation,
  };

  final span = _tracer().startSpan(
    'plivo $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.product != null) {
        extras.add(OTel.attributeString('plivo.product', res.product!));
      }
      if (res.authId != null) {
        extras.add(OTel.attributeString('plivo.auth_id', res.authId!));
      }
      if (res.from != null) {
        extras.add(OTel.attributeString('plivo.from', res.from!));
      }
      if (res.to != null) {
        extras.add(OTel.attributeString('plivo.to', res.to!));
      }
      if (res.countryCode != null) {
        extras.add(OTel.attributeString(
          'plivo.country_code',
          res.countryCode!,
        ));
      }
      if (res.messageUuid != null) {
        extras.add(OTel.attributeString(
          'plivo.message.uuid',
          res.messageUuid!,
        ));
      }
      if (res.messageType != null) {
        extras.add(OTel.attributeString(
          'plivo.message.type',
          res.messageType!,
        ));
      }
      if (res.messageStatus != null) {
        extras.add(OTel.attributeString(
          'plivo.message.status',
          res.messageStatus!,
        ));
        if (res.messageStatus == 'failed' ||
            res.messageStatus == 'undelivered' ||
            res.messageStatus == 'rejected') {
          span.setStatus(
            SpanStatusCode.Error,
            'Plivo message ${res.messageStatus}',
          );
        }
      }
      if (res.totalRate != null) {
        extras.add(OTel.attributeInt(
          'plivo.message.total_rate_micros',
          res.totalRate!,
        ));
      }
      if (res.totalCharge != null) {
        extras.add(OTel.attributeInt(
          'plivo.message.total_charge_micros',
          res.totalCharge!,
        ));
      }
      if (res.units != null) {
        extras.add(OTel.attributeInt('plivo.message.units', res.units!));
      }
      if (res.callUuid != null) {
        extras.add(OTel.attributeString('plivo.call.uuid', res.callUuid!));
      }
      if (res.callDirection != null) {
        extras.add(OTel.attributeString(
          'plivo.call.direction',
          res.callDirection!,
        ));
      }
      if (res.callStatus != null) {
        extras.add(OTel.attributeString(
          'plivo.call.status',
          res.callStatus!,
        ));
        if (res.callStatus == 'failed') {
          span.setStatus(SpanStatusCode.Error, 'Plivo call failed');
        }
      }
      if (res.callDurationSec != null) {
        extras.add(OTel.attributeInt(
          'plivo.call.duration_sec',
          res.callDurationSec!,
        ));
      }
      if (res.callBillDurationSec != null) {
        extras.add(OTel.attributeInt(
          'plivo.call.bill_duration_sec',
          res.callBillDurationSec!,
        ));
      }
      if (res.verifyId != null) {
        extras.add(OTel.attributeString('plivo.verify.id', res.verifyId!));
      }
      if (res.verifyStatus != null) {
        extras.add(OTel.attributeString(
          'plivo.verify.status',
          res.verifyStatus!,
        ));
        if (res.verifyStatus == 'failed' || res.verifyStatus == 'expired') {
          span.setStatus(
            SpanStatusCode.Error,
            'Plivo verify ${res.verifyStatus}',
          );
        }
      }
      if (res.verifyChannel != null) {
        extras.add(OTel.attributeString(
          'plivo.verify.channel',
          res.verifyChannel!,
        ));
      }
      if (res.whatsappTemplateName != null) {
        extras.add(OTel.attributeString(
          'plivo.whatsapp.template.name',
          res.whatsappTemplateName!,
        ));
      }
      if (res.whatsappTemplateNamespace != null) {
        extras.add(OTel.attributeString(
          'plivo.whatsapp.template.namespace',
          res.whatsappTemplateNamespace!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString('plivo.error.code', res.errorCode!));
        span.setStatus(SpanStatusCode.Error, 'Plivo ${res.errorCode}');
      }
      if (res.errorMessage != null) {
        extras.add(OTel.attributeString(
          'plivo.error.message',
          res.errorMessage!,
        ));
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(SpanStatusCode.Error, 'Plivo HTTP ${res.statusCode}');
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
