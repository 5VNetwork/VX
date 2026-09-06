part of 'home.dart';

class _Subscription extends StatefulWidget {
  const _Subscription();

  @override
  State<_Subscription> createState() => _SubscriptionState();
}

class _SubscriptionState extends State<_Subscription> {
  Subscription? subscription;
  StreamSubscription<List<MySubscription>>? _subscriptionStream;

  @override
  void initState() {
    super.initState();
    _subscriptionStream = context
        .read<OutboundRepo>()
        .getStreamOfSubs(limit: 1)
        .listen((value) {
          if (mounted) {
            setState(() {
              subscription = value.firstOrNull;
            });
          }
        });
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return const SizedBox();
    }

    return _SubscriptionCard(subscription: subscription!);
  }
}

class _SubScriptionById extends StatelessWidget {
  const _SubScriptionById({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Subscription?>(
      future: context.read<OutboundRepo>().getSubById(id),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        return snapshot.data == null
            ? const SizedBox()
            : Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SubscriptionCard(subscription: snapshot.data!),
            );
      },
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({super.key, required this.subscription});
  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final parsedData = SubscriptionData.parse(subscription!.description);
    final hasUpdateError =
        subscription!.lastSuccessUpdate != subscription!.lastUpdate;
    final colorScheme = Theme.of(context).colorScheme;

    // Check if subscription is expiring soon (within 7 days)
    final isExpiringSoon =
        parsedData?.expirationDate != null &&
        parsedData!.expirationDate!.difference(DateTime.now()).inDays <= 7 &&
        parsedData.expirationDate!.isAfter(DateTime.now());

    // Check if expired
    final isExpired =
        parsedData?.expirationDate != null &&
        parsedData!.expirationDate!.isBefore(DateTime.now());
    return SizedBox(
      height: 120,
      child: GestureDetector(
        onTap: () {
          context.read<SubscriptionBloc>().add(
            UpdateSubscriptionEvent(subscription!),
          );
        },
        child: HomeCard(
          title: subscription!.name,
          icon: Icons.subscriptions_rounded,
          button: BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (ctx, satte) {
              return satte.updatingSubs.contains(subscription!.id)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded);
            },
          ),
          child: Expanded(
            child: Column(
              children: [
                const Spacer(),
                // Show parsed data if available
                if (parsedData?.expirationDate != null ||
                    parsedData?.remainingData != null) ...[
                  // Data usage section
                  if (parsedData?.remainingData != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.data_usage_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          parsedData!.totalData != null
                              ? '${parsedData.remainingData} / ${parsedData.totalData}'
                              : parsedData.remainingData!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const Spacer(),
                        if (parsedData.expirationDate != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isExpired
                                    ? Icons.error
                                    : isExpiringSoon
                                    ? Icons.warning_amber_rounded
                                    : Icons.calendar_month,
                                size: 16,
                                color: isExpired
                                    ? colorScheme.error
                                    : colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'yyyy-MM-dd',
                                ).format(parsedData.expirationDate!),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ]
                // Show description if no parsed data available
                else if (subscription!.description.isNotEmpty) ...[
                  AutoSizeText(
                    subscription!.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    minFontSize: 10,
                  ),
                ],
                // Push content to bottom
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      hasUpdateError ? Icons.error_outline : Icons.schedule,
                      size: 12,
                      color: hasUpdateError
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hasUpdateError
                            ? AppLocalizations.of(context)!.failure
                            : '${AppLocalizations.of(context)!.updatedAt} ${DateFormat('MM-dd HH:mm', Localizations.localeOf(context).toString()).format(DateTime.fromMillisecondsSinceEpoch(subscription!.lastSuccessUpdate))}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: hasUpdateError
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
