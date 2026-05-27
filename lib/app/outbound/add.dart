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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
import 'package:vx/app/outbound/add_chain_handler.dart';
import 'package:vx/app/outbound/outbound_page.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:vx/widgets/outbound_handler_form/outbound_handler_form.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/outbound/subscription_bloc.dart';
import 'package:vx/app/outbound/subscription_page.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/app/layout_provider.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/widgets/form_dialog.dart';
import 'package:vx/widgets/pro_icon.dart';
import 'package:vx/widgets/pro_promotion.dart';
import 'package:vx/widgets/take_picture.dart';
import 'package:zxing2/qrcode.dart';
import 'package:provider/provider.dart';
import 'package:vx/l10n/app_localizations.dart';

class AddMenuAnchor extends StatelessWidget {
  const AddMenuAnchor({
    super.key,
    this.colored = false,
    this.elevatedButton = false,
  });
  final bool colored;
  final bool elevatedButton;
  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_paste),
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(AppLocalizations.of(context)!.clipboard),
          ),
          onPressed: () => _onClipboardClicked(context),
        ),
        if (Platform.isAndroid || Platform.isIOS)
          MenuItemButton(
            leadingIcon: const Icon(Icons.qr_code_scanner_rounded),
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(AppLocalizations.of(context)!.qrCode),
            ),
            onPressed: () async {
              final outbloc = context.read<OutboundBloc>();
              final subBloc = context.read<SubscriptionBloc>();
              final barcode = await Navigator.of(context, rootNavigator: true)
                  .push<Barcode?>(
                    MaterialPageRoute(
                      builder: (ctx) {
                        return const ScanQrCode();
                      },
                    ),
                  );
              if (barcode == null || barcode.displayValue == null) {
                return;
              }
              logger.d(barcode.displayValue);
              // final imageBytes = barcode.rawBytes;
              // if (imageBytes == null) {
              //   return;
              // }
              // late String data;
              // try {
              //   final image = img.decodeImage(imageBytes);
              //   if (image == null) {
              //     throw Exception('Failed to decode image');
              //   }
              //   data = getQrCodeData(image);
              //   if (data.isEmpty) {
              //     throw Exception('Failed to decode QR code');
              //   }
              // } catch (e) {
              //   logger.d('decode qr code error', error: e);
              //   rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
              //       content:
              //           Text(AppLocalizations.of(context)!.decodeQrCode)));
              //   return;
              // }
              await getNodesFromUrls(
                barcode.displayValue!,
                context,
                outbloc,
                subBloc,
              );
            },
          ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(AppLocalizations.of(context)!.inputManually),
          ),
          onPressed: () async {
            final outBloc = context.read<OutboundBloc>();
            final subBloc = context.read<SubscriptionBloc>();
            late Object? result;
            if (Provider.of<MyLayout>(context, listen: false).fullScreen()) {
              result = await Navigator.of(context, rootNavigator: true).push(
                CupertinoPageRoute(
                  builder: (ctx) {
                    return const AddDialog(fullScreen: true, initialIndex: 1);
                  },
                ),
              );
            } else {
              result = await showGeneralDialog(
                context: context,
                barrierDismissible: false,
                barrierLabel: AppLocalizations.of(context)!.edit,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const AddDialog(fullScreen: false, initialIndex: 1),
              );
            }
            if (result != null) {
              if (result is HandlerConfig) {
                outBloc.add(AddHandlerEvent(result));
              } else if (result is SubscriptionFormData) {
                subBloc.add(AddSubscriptionEvent(result.name, result.link));
              } else if (result is ChainHandlerConfig) {
                outBloc.add(AddHandlerEvent(HandlerConfig(chain: result)));
              }
            }
          },
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.file_open_rounded),
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(AppLocalizations.of(context)!.selectFromFile),
          ),
          onPressed: () async {
            final outbloc = context.read<OutboundBloc>();
            final subBloc = context.read<SubscriptionBloc>();
            final result = await FilePicker.platform.pickFiles(
              type: FileType.any,
              withData: true,
            );
            if (result == null) {
              return;
            }
            await getNodesFromUrls(
              utf8.decode(result.files.first.bytes!),
              context,
              outbloc,
              subBloc,
            );
          },
        ),
      ],
      builder: (context, controller, child) {
        if (colored) {
          return IconButton.filledTonal(
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              iconSize: 20,
              minimumSize: const Size(30, 30),
            ),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(Icons.add_rounded),
          );
        }
        return elevatedButton
            ? FilledButton.icon(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                label: Text(AppLocalizations.of(context)!.addNode),
                icon: const Icon(Icons.add_rounded),
              )
            : IconButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                icon: const Icon(Icons.add_rounded),
              );
      },
    );
  }

  void _onClipboardClicked(BuildContext context) async {
    final outbloc = context.read<OutboundBloc>();
    final subBloc = context.read<SubscriptionBloc>();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        content: Text(AppLocalizations.of(context)!.gettingNodesSubscriptions),
        width: 300,
      ),
    );
    // get data from clipboard
    String? data = await Pasteboard.text;
    // if the text clipboard is empty, try to get image from clipboard
    if ((data?.isEmpty ?? true)) {
      final raw = await Pasteboard.image;
      if (raw == null || raw.isEmpty) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.unableToGetNodesEmptyClipboard,
            ),
          ),
        );
        return;
      }
      final image = img.decodeImage(raw);
      if (image == null) {
        if (context.mounted) {
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.decodeQrCode)),
          );
        }
        return;
      }
      data = getQrCodeData(image);
    }
    if (data == null || data.isEmpty) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.unableToGetNodesEmptyClipboard,
          ),
        ),
      );
      return;
    }
    await getNodesFromUrls(data, context, outbloc, subBloc);
  }
}

Future<void> getNodesFromUrls(
  String data,
  BuildContext context,
  OutboundBloc outbloc,
  SubscriptionBloc subBloc,
) async {
  try {
    final outboundRepo = context.read<OutboundRepo>();
    final isSubscription = data.startsWith('http');
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    if (isSubscription) {
      // parse the url to get the remark
      final url = Uri.parse(data);
      String tag = url.fragment;
      if (tag.isEmpty) {
        final t = await showStringForm(
          context,
          title: AppLocalizations.of(context)!.addRemark,
          cancelText: AppLocalizations.of(context)!.skip,
        );
        if (t != null && t.isNotEmpty) tag = t;
      }
      if (tag.isEmpty) {
        // generate a random and unique tag
        int id = 1;
        while (true) {
          if ((await outboundRepo.getSubsByName('Sub $id')).isEmpty) {
            tag = 'Sub $id';
            break;
          }
          id++;
        }
      }
      subBloc.add(AddSubscriptionEvent(tag, data));
    } else {
      // try decode as HandlerConfigs first
      List<HandlerConfig> configs = [];
      try {
        final hc = HandlerConfigs.fromBuffer(base64Url.decode(data));
        configs.addAll(hc.configs);
      } catch (e) {
        logger.d('HandlerConfigs.fromBuffer', error: e);
      }
      if (configs.isNotEmpty) {
        final group = await _showGroupPickerDialog(context, outboundRepo);
        outbloc.add(AddHandlersEvent(groupName: group, configs));
        return;
      } else {
        // decode as urls
        final result = await context.read<XApiClient>().decode(data);
        final group = await _showGroupPickerDialog(context, outboundRepo);
        outbloc.add(
          AddHandlersEvent(
            groupName: group,
            result.handlers.map((e) => HandlerConfig(outbound: e)).toList(),
          ),
        );
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            action: SnackBarAction(
              label: rootLocalizations()?.failedNodes ?? '',
              onPressed: () {
                showDialog(
                  context: rootNavigationKey.currentContext!,
                  builder: (context) => SimpleDialog(
                    title: Text(AppLocalizations.of(context)!.failedNodes),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    children: result.failedNodes.map((e) => Text(e)).toList(),
                  ),
                );
              },
            ),
            content: Text(
              rootLocalizations()?.decodeResult(
                    result.handlers.length,
                    result.failedNodes.length,
                  ) ??
                  '',
            ),
          ),
        );
      }
    }
  } catch (e) {
    logger.d('getNodes error', error: e);

    // TODO: inform a user why it failed
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Text(AppLocalizations.of(context)!.unableToGetNodes),
      ),
    );
  }
}

Future<String> _showGroupPickerDialog(
  BuildContext context,
  OutboundRepo outboundRepo,
) async {
  final groups = await outboundRepo.getGroups();
  final controller = TextEditingController();
  final chosen = await showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.addToGroup),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                decoration: InputDecoration(border: const OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            MenuAnchor(
              menuChildren: groups
                  .map(
                    (e) => MenuItemButton(
                      onPressed: () => Navigator.pop(dialogContext, e.name),
                      child: Text(groupNametoLocalizedName(context, e.name)),
                    ),
                  )
                  .toList(),
              builder: (context, controller, child) => TextButton(
                onPressed: () => controller.open(),
                child: Text(AppLocalizations.of(context)!.selectGroup),
              ),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ],
        );
      },
    ),
  );
  controller.dispose();
  return chosen ?? defaultGroupName;
}

String getQrCodeData(img.Image image) {
  final source = RGBLuminanceSource(
    image.width,
    image.height,
    image
        .convert(numChannels: 4)
        .getBytes(order: img.ChannelOrder.abgr)
        .buffer
        .asInt32List(),
  );
  // decode qr code
  final bitMap = BinaryBitmap(GlobalHistogramBinarizer(source));
  final qr = QRCodeReader().decode(bitMap);
  return qr.text;
}

class AddDialog extends StatefulWidget {
  const AddDialog({super.key, required this.fullScreen, this.initialIndex = 0});
  final bool fullScreen;
  final int initialIndex;
  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subFormKey = GlobalKey<FormState>();
  final _chainFormKey = GlobalKey<FormState>();
  final _widgetKey = GlobalKey<OutboundHandlerFormState>();
  late TabController _tabController;
  final _subFormData = SubscriptionFormData();
  final _chainFormWidgetKey = GlobalKey<ChainHandlerFormState>();

  @override
  void initState() {
    _tabController = TabController(
      vsync: this,
      length: 3,
      initialIndex: widget.initialIndex,
    );
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveNode() {
    final allGood = _formKey.currentState?.validate();
    if (allGood == true) {
      OutboundHandlerConfig handler =
          (_widgetKey.currentState as OutboundHandlerConfigGetter)
              .outboundHandler;
      context.pop(HandlerConfig(outbound: handler));
    }
  }

  void _saveSub() async {
    final allGood = _subFormKey.currentState?.validate();
    if (allGood == true) {
      context.pop(_subFormData);
    }
  }

  void _onSaveChain(BuildContext context) async {
    final allGood = _chainFormKey.currentState?.validate();
    if (allGood == true) {
      try {
        ChainHandlerConfig config =
            (_chainFormWidgetKey.currentState as ChainHandlerFormState).config;
        if (config.handlers.length <= 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 5),
              content: Text(AppLocalizations.of(context)!.atLeastTwoNodes),
            ),
          );
          return;
        }
        context.pop(config);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  void _onPressed(BuildContext context) async {
    switch (_tabController.index) {
      case 0:
        _saveNode();
        break;
      case 1:
        _saveSub();
        break;
      case 2:
        _onSaveChain(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: AppLocalizations.of(context)!.node),
        Tab(text: AppLocalizations.of(context)!.subscription),
        Tab(
          child: context.read<AuthBloc>().state.pro
              ? Text(AppLocalizations.of(context)!.chainProxy)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppLocalizations.of(context)!.chainProxy),
                    proIconSmall,
                  ],
                ),
        ),
      ],
    );
    return widget.fullScreen
        ? Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: !Platform.isMacOS
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    )
                  : null,
              actions: [
                if (Platform.isMacOS)
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                TextButton(
                  onPressed: () => _onPressed(context),
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
              bottom: tabBar,
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: OutboundHandlerForm(
                      formKey: _formKey,
                      key: _widgetKey,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SubscriptionForm(
                    data: _subFormData,
                    formKey: _subFormKey,
                  ),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: context.read<AuthBloc>().state.pro
                        ? ChainHandlerForm(
                            formKey: _chainFormKey,
                            key: _chainFormWidgetKey,
                          )
                        : const ProPromotion(),
                  ),
                ),
              ],
            ),
          )
        : ScaffoldMessenger(
            child: Dialog(
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Scaffold(
                  appBar: AppBar(
                    toolbarHeight: 0,
                    automaticallyImplyLeading: false,
                    bottom: tabBar,
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: OutboundHandlerForm(
                                  formKey: _formKey,
                                  key: _widgetKey,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: SubscriptionForm(
                                data: _subFormData,
                                formKey: _subFormKey,
                              ),
                            ),
                            ScaffoldMessenger(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: context.read<AuthBloc>().state.pro
                                      ? ChainHandlerForm(
                                          formKey: _chainFormKey,
                                          key: _chainFormWidgetKey,
                                        )
                                      : const ProPromotion(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                fixedSize: const Size(100, 40),
                                elevation: 1,
                              ),
                              onPressed: () => context.pop(),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                            const Gap(10),
                            Builder(
                              builder: (context) {
                                return FilledButton(
                                  style: FilledButton.styleFrom(
                                    fixedSize: const Size(100, 40),
                                    elevation: 1,
                                  ),
                                  onPressed: () => _onPressed(context),
                                  child: Text(
                                    AppLocalizations.of(context)!.save,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}

// class PostAddSubscriptionDialog extends StatefulWidget {
//   const PostAddSubscriptionDialog({super.key});

//   @override
//   State<PostAddSubscriptionDialog> createState() =>
//       _PostAddSubscriptionDialogState();
// }

// class _PostAddSubscriptionDialogState extends State<PostAddSubscriptionDialog> {
//   final TextEditingController _controller = TextEditingController();
//   @override
//   void initState() {
//     _controller.addListener(() => setState(() {}));
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       actions: [
//         FilledButton.tonal(
//             onPressed: () => Navigator.of(context).pop(_controller.text),
//             child: const Text('跳过')),
//         FilledButton(
//             onPressed: _controller.text.isNotEmpty
//                 ? () => Navigator.of(context).pop(_controller.text)
//                 : null,
//             child: const Text('确定')),
//       ],
//       content: TextField(
//           controller: _controller,
//           decoration: const InputDecoration(labelText: '备注')),
//       title: const Text('添加一个备注？'),
//     );
//   }
// }
