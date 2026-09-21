import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lapse/core/formatting/date_labels.dart';
import 'package:lapse/core/formatting/money_formatter.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/formatting/subscription_labels.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_detail.dart';

final _dayMonthYear = DateFormat('d MMM y', 'en_US');

class DetailInfoCard extends StatelessWidget {
  const DetailInfoCard({
    required this.detail,
    required this.onOpenCancelLink,
    super.key,
  });

  final SubscriptionDetail detail;
  final VoidCallback onOpenCancelLink;

  @override
  Widget build(BuildContext context) {
    final c = context.lapse.colors;
    final sub = detail.subscription;
    final payment = sub.paymentMethod?.trim() ?? '';
    final notes = sub.notes?.trim() ?? '';
    final link = sub.cancelUrl?.trim() ?? '';

    return LapseRowGroup(
      children: [
        _InfoRow(
          label: 'Price',
          value: formatMoney(sub.price),
          suffix: perPeriodLabel(sub.period, customDays: sub.customDays),
          tabular: true,
        ),
        _InfoRow(
          label: 'Billing cycle',
          value: periodLabel(sub.period, customDays: sub.customDays),
        ),
        if (!sub.isCancelled)
          _InfoRow(
            label: sub.isTrial ? 'First charge' : 'Next charge',
            value: _dayMonthYear.format(sub.nextBillingDate.toDateTime()),
            tabular: true,
          ),
        if (payment.isNotEmpty)
          _InfoRow(label: 'Payment method', value: payment, tabular: true),
        _InfoRow(
          label: 'Total paid so far',
          value: detail.totalPaid.isPositive
              ? formatMoney(detail.totalPaid)
              : 'Nothing yet',
          muted: !detail.totalPaid.isPositive,
          tabular: true,
        ),
        _InfoRow(
          label: 'Reminders',
          value: reminderSummary(sub.reminderOffsets),
        ),
        if (link.isNotEmpty)
          _InfoRow(
            label: 'Cancel link',
            value: prettyUrl(link),
            color: c.primary,
            icon: Icons.north_east_rounded,
            onTap: onOpenCancelLink,
          ),
        if (notes.isNotEmpty)
          _InfoRow(label: 'Notes', value: notes, multiline: true),
        _InfoRow(label: 'Started', value: fullDateLabel(sub.startDate)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.suffix,
    this.color,
    this.icon,
    this.onTap,
    this.tabular = false,
    this.muted = false,
    this.multiline = false,
  });

  final String label;
  final String value;
  final String? suffix;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool tabular;
  final bool muted;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final labelStyle = lapse.text.body.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: c.inkMuted,
    );
    var valueStyle = lapse.text.body.copyWith(
      fontSize: 15,
      fontWeight: multiline ? FontWeight.w500 : FontWeight.w700,
      color: color ?? (muted ? c.inkSubtle : c.ink),
    );
    if (tabular) valueStyle = LapseTypography.money(valueStyle);

    final valueText = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: value),
          if (suffix != null)
            TextSpan(
              text: ' $suffix',
              style: TextStyle(
                color: c.inkSubtle,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      textAlign: multiline ? TextAlign.start : TextAlign.end,
      maxLines: multiline ? null : 2,
      overflow: multiline ? null : TextOverflow.ellipsis,
      style: valueStyle,
    );

    final Widget content;
    if (multiline) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 6),
            valueText,
          ],
        ),
      );
    } else {
      content = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.input),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.5,
                  ),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(child: valueText),
                if (icon != null) ...[
                  const SizedBox(width: 6),
                  Icon(icon, size: 18, color: color ?? c.inkSubtle),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final spoken = suffix == null ? value : '$value $suffix';
    if (onTap == null) {
      return MergeSemantics(child: content);
    }
    return Semantics(
      button: true,
      link: true,
      label: '$label, $spoken',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
