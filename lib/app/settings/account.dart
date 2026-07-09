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

import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_common/common.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/outbound/subscription_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import 'package:vx/app/settings/privacy.dart';
import 'package:vx/auth/user.dart';
import 'package:vx/common/common.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:flutter_common/auth/auth_provider.dart';
import 'package:flutter_common/auth/sign_in_page.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/activate.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/qr.dart';
import 'package:vx/widgets/divider.dart';
import 'package:vx/widgets/pro_icon.dart';
import 'package:flutter/services.dart';
import 'package:vx/widgets/take_picture.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  DateTime? _lastRefreshTime;
  static const Duration _refreshCooldown = Duration(seconds: 5);
  bool _isActivating = false;
  bool get _canRefresh {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!) >= _refreshCooldown;
  }

  void _refreshUser() {
    if (_canRefresh) {
      logger.d('refresh user');
      _lastRefreshTime = DateTime.now();
      context.read<AuthProvider>().refreshUser();
    }
  }

  Future<void> _activate() async {
    setState(() {
      _isActivating = true;
    });
    final authBloc = context.read<AuthBloc>();
    try {
      final token = supabase.auth.currentSession?.accessToken;
      if (token == null) {
        throw 'No Token';
      }
      final storage = context.read<FlutterSecureStorage>();
      String? uniqueId = await storage.read(key: uniqueIdKey);
      if (uniqueId == null) {
        uniqueId = const Uuid().v4();
        await storage.write(key: uniqueIdKey, value: uniqueId);
      }
      final response = await supabase.functions.invoke(
        'licence',
        headers: {'Authorization': 'Bearer $token'},
        body: (await getConstDeviceInfo(uniqueId)).hash(),
      );
      if (response.status == 200) {
        await storage.write(key: 'licence', value: jsonEncode(response.data));
        logger.d('licence: ${response.data}');
        if (await validateLicence(Licence.fromJson(response.data), uniqueId)) {
          authBloc.add(const AuthActivatedEvent());
        }
      }
    } catch (e) {
      logger.e('activate error: $e');
    } finally {
      setState(() {
        _isActivating = false;
      });
    }
  }

  bool get _showGoogle {
    if (!Platform.isWindows) {
      return true;
    }
    return !isRunningAsAdmin;
  }

  bool get _showMicrosoft {
    if (!Platform.isWindows) {
      return true;
    }
    return !isRunningAsAdmin;
  }

  bool get _showApple {
    return (Platform.isMacOS && appFlavor != 'pkg') || Platform.isIOS;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: Text(AppLocalizations.of(context)!.account))
          : null,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state.user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SignInPage(
                    showGoogle: _showGoogle,
                    showMicrosoft: isPkg || !applePlatform,
                    showApple: _showApple,
                    termOfServiceUrl: termOfServiceUrl,
                    privacyPolicyUrl: privacyPolicyUrl,
                  ),
                  Text(
                    AppLocalizations.of(context)!.newUserProTrial,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.email,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AutoSizeText(
                        state.user!.email,
                        maxLines: 2,
                        minFontSize: 12,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                if (state.user!.lifetimePro == true ||
                    state.user!.level == UserLevel.max)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        avatar: proIcon,
                        label: Text(
                          state.user!.level == UserLevel.max ? 'Max' : 'Pro',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                if (state.user!.lifetimePro == false)
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.proExpiredAt,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        state.user!.proExpiredAt != null
                            ? DateFormat(
                                'yyyy-MM-dd',
                              ).format(state.user!.proExpiredAt!.toLocal())
                            : AppLocalizations.of(context)!.expired,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      IconButton(
                        onPressed: _canRefresh ? _refreshUser : null,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                Center(
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.read<AuthProvider>().logOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                        ),
                        child: Text(AppLocalizations.of(context)!.logout),
                      ),
                      const Gap(10),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                AppLocalizations.of(context)!.deleteAccount,
                              ),
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.deleteAccountConfirm,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context
                                        .read<AuthProvider>()
                                        .deleteAccount();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.delete,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.errorContainer,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onErrorContainer,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.deleteAccount,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(10),
                if (state.isActivated) const ActivatedIcon(),
                if (!state.isActivated && state.user!.lifetimePro == true)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          onPressed: _activate,
                          icon: _isActivating
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.verified_user, size: 20),
                          label: Text(AppLocalizations.of(context)!.activate),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const Gap(8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            AppLocalizations.of(context)!.activateDesc,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Gap(20),
                divider,
                const Gap(20),
                const _Subscription(),
                // const _Invitation(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Invitation extends StatefulWidget {
  const _Invitation();

  @override
  State<_Invitation> createState() => __InvitationState();
}

class __InvitationState extends State<_Invitation> {
  bool _isLoading = true;
  String? _error;
  String? _invitationCode;
  int? _remainingTime;
  bool? _invitationEnjoyed;
  final _invitationCodeController = TextEditingController();
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _getInvitationCode();
  }

  void _getInvitationCode() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        return;
      }
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .single();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _invitationCode = response['invite_code'] as String?;
          _remainingTime = response['invite_code_remaining_times'] as int?;
          _invitationEnjoyed = response['invitation_enjoyed'] as bool?;
        });
      }
    } catch (e) {
      logger.e('Failed to fetch invitation code: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _invitationCodeController.dispose();
    super.dispose();
  }

  void _useInvitationCode(String code) async {
    if (code.isEmpty) {
      return;
    }
    setState(() {
      _applying = true;
    });
    try {
      final authProvider = context.read<AuthProvider>();
      final token = supabase.auth.currentSession?.accessToken;
      if (token == null) {
        throw 'No Token';
      }
      final response = await supabase.functions.invoke(
        'invitation',
        headers: {'Authorization': 'Bearer $token'},
        body: code,
      );
      if (response.status == 200) {
        setState(() {
          _invitationEnjoyed = true;
        });
        authProvider.refreshUser();
      }
    } catch (e) {
      logger.e('Failed to use invitation code: $e');
      snack(e.toString());
    } finally {
      setState(() {
        _applying = false;
      });
    }
  }

  void _copyInvitationCode() async {
    if (_invitationCode == null || _invitationCode!.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _invitationCode!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.copiedToClipboard),
        ),
      );
    }
  }

  void _shareInvitationCode() async {
    if (_invitationCode == null || _invitationCode!.isEmpty) {
      return;
    }
    shareQrCode(context, _invitationCode!);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_invitationCode != null &&
            _remainingTime != null &&
            _remainingTime! > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Gap(8),
                  Text(
                    AppLocalizations.of(context)!.myInvitationCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: SelectableText(
                  _invitationCode!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Gap(5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  AppLocalizations.of(context)!.myInvitationCodeDesc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Gap(5),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _copyInvitationCode,
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(AppLocalizations.of(context)!.copy),
                  ),
                  const Gap(10),
                  FilledButton.icon(
                    onPressed: _shareInvitationCode,
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: Text(AppLocalizations.of(context)!.qrCode),
                  ),
                ],
              ),
              const Gap(5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '$_remainingTime ${AppLocalizations.of(context)!.remainingTime}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        // Divider between sections
        if (_invitationEnjoyed != true)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(20),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
              const Gap(20),
              Row(
                children: [
                  Icon(
                    Icons.input,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Gap(8),
                  Text(
                    AppLocalizations.of(context)!.useInvitationCode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Gap(12),
              TextField(
                controller: _invitationCodeController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.confirmation_number),
                  helperText: AppLocalizations.of(
                    context,
                  )!.useInvitationCodeDesc,
                  helperMaxLines: 3,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                enabled: !_applying,
              ),
              const Gap(10),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _invitationCodeController,
                builder: (context, value, child) {
                  final isEmpty = value.text.isEmpty;
                  return FilledButton.icon(
                    onPressed: _applying || isEmpty
                        ? null
                        : () => _useInvitationCode(value.text),
                    icon: _applying
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(AppLocalizations.of(context)!.apply),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  );
                },
              ),
              const Gap(10),
              if (Platform.isAndroid || Platform.isIOS)
                FilledButton.icon(
                  onPressed: () async {
                    final barcode =
                        await Navigator.of(
                          context,
                          rootNavigator: true,
                        ).push<Barcode?>(
                          MaterialPageRoute(
                            builder: (ctx) {
                              return const ScanQrCode();
                            },
                          ),
                        );
                    if (barcode == null || barcode.displayValue == null) {
                      return;
                    }
                    _useInvitationCode(barcode.rawValue ?? '');
                  },
                  icon: _applying
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.scanQrCode),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Subscription extends StatefulWidget {
  const _Subscription({super.key});

  @override
  State<_Subscription> createState() => __SubscriptionState();
}

class __SubscriptionState extends State<_Subscription> {
  static const _maxSubName = 'Max';
  bool _adding = false;
  bool _resetting = false;

  String _fetchSubscriptionUrl(String secret) {
    return '$supabaseUrl/functions/v1/fetch/$secret';
  }

  Future<String> _getFetchSecret() async {
    return await supabase.rpc('get_fetch_secret') as String;
  }

  Future<String> _resetFetchSecret() async {
    return await supabase.rpc('reset_fetch_secret') as String;
  }

  Future<void> _addFreeSubscription() async {
    setState(() {
      _adding = true;
    });
    try {
      final outboundRepo = context.read<OutboundRepo>();
      final existing = await outboundRepo.getSubsByName(_maxSubName);
      if (existing.isNotEmpty) {
        snack('Subscription "$_maxSubName" already exists');
        return;
      }
      final secret = await _getFetchSecret();
      final url = _fetchSubscriptionUrl(secret);
      if (!mounted) {
        return;
      }
      context.read<SubscriptionBloc>().add(
        AddSubscriptionEvent(_maxSubName, url),
      );
      snack('Added subscription "$_maxSubName"');
    } catch (e) {
      logger.e('Failed to add free subscription: $e');
      snack(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
        });
      }
    }
  }

  Future<void> _resetSubscriptionLink() async {
    setState(() {
      _resetting = true;
    });
    try {
      final outboundRepo = context.read<OutboundRepo>();
      final secret = await _resetFetchSecret();
      final url = _fetchSubscriptionUrl(secret);
      final existing = await outboundRepo.getSubsByName(_maxSubName);
      if (existing.isNotEmpty) {
        if (!mounted) {
          return;
        }
        context.read<SubscriptionBloc>().add(
          SubscriptionEditedEvent(id: existing.first.id, link: url),
        );
        snack('Reset subscription link for "$_maxSubName"');
      } else {
        snack('Subscription link reset');
      }
    } catch (e) {
      logger.e('Failed to reset subscription link: $e');
      snack(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _resetting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMaxUser =
        context.watch<AuthBloc>().state.user?.level == UserLevel.max;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMaxUser)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l10n.maxUsersOnly,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        FilledButton(
          onPressed: isMaxUser && !_adding ? _addFreeSubscription : null,
          child: _adding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context)!.addFreeSubscription),
        ),
        const Gap(10),
        Text(
          AppLocalizations.of(context)!.addFreeSubscriptionDesc(_maxSubName),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(10),
        FilledButton(
          onPressed: isMaxUser && !_resetting ? _resetSubscriptionLink : null,
          child: _resetting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context)!.resetSubscriptionLink),
        ),
        const Gap(10),
        Text(
          AppLocalizations.of(context)!.resetSubscriptionLinkDesc,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
