// Copyright (C) 2026 5V Network LLC <5vnetwork@proton.me>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_common/common.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:store_checker/store_checker.dart';
import 'package:vx/common/common.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vx/app/layout_provider.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/iap/pro.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/widgets/pro_icon.dart';

final useStripe =
    Platform.isWindows ||
    (androidApkRelease) ||
    appFlavor == "pkg" ||
    Platform.isLinux;
void showProPromotionDialog(
  BuildContext context, {
  bool showTitle = true,
}) async {
  if (Platform.isIOS) {
    final source = await installationSource!;
    if (source == Source.IS_INSTALLED_FROM_TEST_FLIGHT) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.visitWebsiteToPurchasePro),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        ),
      );
    }
  }

  if (Provider.of<MyLayout>(context, listen: false).isCompact) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: largeProIcon),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: !useStripe
                ? IAPPurchase(showTitle: showTitle)
                : const ProPromotion(),
          ),
        ),
      ),
    );
    // showBottomSheet(context: context, builder: (context) => ProPromotion());
  } else {
    showDialog(
      context: context,
      barrierDismissible: useStripe ? true : false,
      builder: (context) => AlertDialog(
        title: largeProIcon,
        actions: [
          if (!useStripe)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
        ],
        content: !useStripe
            ? IAPPurchase(showTitle: showTitle)
            : const ProPromotion(),
      ),
    );
  }
}

const proPurchaseUrl = kDebugMode
    ? 'http://localhost:3000/zh#pro'
    : 'https://vx.5vnetwork.com/zh#pro';

const proPaymentLink = false
    ? 'https://buy.stripe.com/test_3cIaEZ0CF5g74EnfWrdIA00'
    : 'https://buy.stripe.com/aFa3cw7WA54zc1PdSI67S01';

Uri getProPaymentLink(String email, String clientReferenceId) {
  String url = proPaymentLink;
  if (email.isNotEmpty) {
    url += '?prefilled_email=${Uri.encodeComponent(email)}';
  }
  if (clientReferenceId.isNotEmpty) {
    url += '&client_reference_id=${Uri.encodeComponent(clientReferenceId)}';
  }
  return Uri.parse(url);
}

const price = '¥30';

class ProPromotion extends StatelessWidget {
  const ProPromotion({super.key});

  void _onPressed(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final uri = user != null
        ? getProPaymentLink(user.email, user.id)
        : Uri.parse(proPaymentLink);
    launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.proFeatureDescription,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(10),
          Row(
            children: [
              Expanded(
                child: BuyLifeTimeCard(
                  onPressed: _onPressed,
                  title: 'Pro',
                  price: price,
                  description: AppLocalizations.of(
                    context,
                  )!.becomePermanentProDescription,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          const Gap(10),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  while (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  context.go('/setting/account');
                },
                child: Text(AppLocalizations.of(context)!.tryPro),
              ),
              Text(
                AppLocalizations.of(context)!.newUserProTrial,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BuyLifeTimeCard extends StatelessWidget {
  const BuyLifeTimeCard({
    super.key,
    required this.onPressed,
    required this.title,
    required this.price,
    required this.description,
  });
  final Function(BuildContext) onPressed;
  final String title;
  final String price;
  final String description;
  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Gap(10),
            Text(
              price,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(10),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(24),
            FilledButton.tonal(
              onPressed: () {
                onPressed(context);
              },
              child: Text(AppLocalizations.of(context)!.purchase),
            ),
          ],
        ),
      ),
    );
  }
}

class IAPPurchase extends StatelessWidget {
  const IAPPurchase({super.key, this.showTitle = true});
  final bool showTitle;

  void _onPressed(BuildContext context) async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.loginBeforePurchase),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.close),
            ),
            TextButton(
              onPressed: () => _goLogin(context),
              child: Text(AppLocalizations.of(context)!.login),
            ),
          ],
        ),
      );
      return;
    }
    final proPurchases = context.read<ProPurchases>();
    try {
      await proPurchases.buy(proPurchases.products.first, user.id);
    } catch (e) {
      logger.e('Error on buy: $e');
    }
  }

  void _goLogin(BuildContext context) {
    while (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    context.go('/setting/account');
  }

  Widget _ifYouHavePaid(
    BuildContext context,
    IAPStateWithPurchaseDetail stateWithPurchaseDetail,
  ) {
    return RichText(
      maxLines: 10,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(
            text: AppLocalizations.of(context)!.ifYouHavePaid(
              stateWithPurchaseDetail.purchaseDetails.purchaseID ?? '',
            ),
          ),
          WidgetSpan(
            child: IconButton(
              iconSize: 16,
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(16, 16),
              ),
              onPressed: () {
                Pasteboard.writeText(
                  stateWithPurchaseDetail.purchaseDetails.purchaseID ?? '',
                );
                rootScaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.copiedToClipboard,
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            Text(
              AppLocalizations.of(context)!.proFeatureDescription,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          if (showTitle) const Gap(10),
          SizedBox(
            width: 400,
            child: Consumer<ProPurchases>(
              builder: (context, proPurchases, child) {
                if (proPurchases.state is IAPStateWithPurchaseDetail) {
                  final stateWithPurchaseDetail =
                      proPurchases.state as IAPStateWithPurchaseDetail;
                  if (stateWithPurchaseDetail.purchaseDetails.status ==
                      PurchaseStatus.canceled) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.purchaseCancelled,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  } else if (stateWithPurchaseDetail.purchaseDetails.status ==
                      PurchaseStatus.pending) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (stateWithPurchaseDetail.verifying ?? false) {
                    if (stateWithPurchaseDetail.purchaseDetails.status ==
                        PurchaseStatus.restored) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(),
                              ),
                              const Gap(10),
                              Text(
                                AppLocalizations.of(context)!.restoringPurchase,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            ),
                            const Gap(10),
                            Text(
                              AppLocalizations.of(context)!.verifyingPurchase,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (stateWithPurchaseDetail.verifyFailed != null) {
                    return Column(
                      children: [
                        Icon(
                          Icons.error,
                          color: Theme.of(context).colorScheme.error,
                          size: 24,
                        ),
                        const Gap(5),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.purchaseVerificationFailed(
                            stateWithPurchaseDetail.verifyFailed!.toLocalString(
                              context,
                            ),
                          ),
                          maxLines: 10,
                        ),
                        const Gap(5),
                        TextButton(
                          onPressed: () {
                            proPurchases.reverify();
                          },
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                        const Gap(10),
                        _ifYouHavePaid(context, stateWithPurchaseDetail),
                      ],
                    );
                  } else if (stateWithPurchaseDetail.invalidPurchase != null) {
                    return Center(
                      child: Column(
                        children: [
                          Text(AppLocalizations.of(context)!.invalidPurchase),
                          const Gap(10),
                          _ifYouHavePaid(context, stateWithPurchaseDetail),
                        ],
                      ),
                    );
                  } else if (stateWithPurchaseDetail.success ?? false) {
                    if (stateWithPurchaseDetail.purchaseDetails.status ==
                        PurchaseStatus.purchased) {
                      return Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            ),
                            const Gap(10),
                            Text(
                              AppLocalizations.of(context)!.purchaseSuccessful,
                            ),
                          ],
                        ),
                      );
                    } else if (stateWithPurchaseDetail.purchaseDetails.status ==
                        PurchaseStatus.restored) {
                      return Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            ),
                            const Gap(10),
                            Text(
                              AppLocalizations.of(context)!.restoreSuccessful,
                            ),
                          ],
                        ),
                      );
                    } else {
                      logger.e(
                        'unknown purchase status: ${stateWithPurchaseDetail.purchaseDetails.status}',
                      );
                    }
                    // return Center(
                    //     child: Row(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     const Icon(Icons.check_circle,
                    //         color: Colors.green, size: 32),
                    //     const Gap(10),
                    //     Text(AppLocalizations.of(context)!.purchaseSuccessful),
                    //   ],
                    // ));
                  } else if (stateWithPurchaseDetail.purchaseDetails.status ==
                      PurchaseStatus.error) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.purchaseFailed(
                          stateWithPurchaseDetail
                                  .purchaseDetails
                                  .error
                                  ?.message ??
                              '',
                        ),
                        maxLines: 10,
                      ),
                    );
                  }
                  return const SizedBox();
                } else {
                  final stateWithoutPurchaseDetail =
                      proPurchases.state as IAPStateWithoutPurchaseDetail;
                  if (stateWithoutPurchaseDetail.storeState ==
                      StoreState.notAvailable) {
                    return Center(
                      child: Row(
                        children: [
                          const Icon(Icons.error),
                          const Gap(10),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.unableToConnectToStore,
                          ),
                        ],
                      ),
                    );
                  } else if (stateWithoutPurchaseDetail.storeState ==
                      StoreState.loading) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (stateWithoutPurchaseDetail.buying) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (proPurchases.products.isNotEmpty)
                        Expanded(
                          child: BuyLifeTimeCard(
                            onPressed: _onPressed,
                            title: proPurchases.products.first.title,
                            price: proPurchases.products.first.price,
                            description:
                                proPurchases.products.first.description,
                          ),
                        ),
                      const Expanded(child: SizedBox()),
                    ],
                  );
                }
              },
            ),
          ),
          const Gap(10),
          if (context.read<AuthBloc>().state.user == null)
            RichText(
              softWrap: true,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: AppLocalizations.of(context)!.loginBeforePurchase,
                  ),
                  WidgetSpan(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _goLogin(context),
                      child: Text(
                        AppLocalizations.of(context)!.login,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
