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

part of 'routing_page.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({
    super.key,
    required this.appSetName,
    this.showLabel = true,
    this.addButtonInWrap = false,
  });
  final String appSetName;
  final bool addButtonInWrap;
  final bool showLabel;
  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  late Stream<List<App>> _stream;
  late SetRepo _setRepo;
  late MenuAnchor _menuAnchor;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setRepo = Provider.of<SetRepo>(context, listen: true);
    _menuAnchor = MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: _onAddApp,
          child: Text(AppLocalizations.of(context)!.mannual),
        ),
        if (Platform.isWindows)
          MenuItemButton(
            onPressed: _onAddFromInstalledApps,
            leadingIcon: const Icon(Icons.list_alt_rounded),
            child: Text(AppLocalizations.of(context)!.selectFromInstalledApps),
          ),
        MenuItemButton(
          onPressed: _onPickFromFile,
          leadingIcon: const Icon(Icons.folder),
          child: Text(AppLocalizations.of(context)!.selectFromFile),
        ),
        MenuItemButton(
          onPressed: _onAddFromClashRuleFiles,
          leadingIcon: const Icon(Icons.document_scanner),
          child: Text(AppLocalizations.of(context)!.addFromClashRuleFiles),
        ),
      ],
      builder: (context, controller, child) {
        return IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(0),
          onPressed: () => controller.open(),
          icon: const Icon(Icons.add_rounded),
        );
      },
    );
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant AppWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appSetName != widget.appSetName) {
      _subscribe();
    }
  }

  void _subscribe() {
    _stream = _setRepo.getAppsStream(widget.appSetName);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onAddApp() async {
    if (Platform.isAndroid) {
      await Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(
          builder: (context) =>
              AddAppIdAndroidScreen(appSetName: widget.appSetName),
        ),
      );
      return;
    }
    final result = await showDialog(
      barrierDismissible: desktopPlatforms ? true : false,
      context: context,
      builder: (context) => AddAppIdDialog(appSetName: widget.appSetName),
    );
    if (result != null && result is AppId) {
      await _setRepo.addApp(widget.appSetName, result);
    }
  }

  void _onAddFromClashRuleFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result != null) {
      try {
        final response = await context.read<XApiClient>().parseClashRuleFile(
          result.files.first.bytes!.toList(),
        );
        await _setRepo.addApps(
          response.appIds
              .map(
                (e) => App(
                  appId: e,
                  icon: null,
                  id: 0,
                  appSetName: widget.appSetName,
                ),
              )
              .toList(),
        );
      } catch (e) {
        snack(e.toString());
      }
    }
  }

  void _onAddFromInstalledApps() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AddAppIdDesktopScreen(appSetName: widget.appSetName),
      ),
    );
  }

  void _onPickFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: Platform.isWindows ? FileType.custom : FileType.any,
      allowedExtensions: Platform.isWindows ? ['exe'] : null,
      dialogTitle: Platform.isWindows
          ? 'Select an executable'
          : 'Select an application',
    );
    if (result != null && result.files.first.path != null) {
      await _setRepo.addApp(
        widget.appSetName,
        AppId(
          type: Platform.isMacOS ? AppId_Type.Prefix : AppId_Type.Exact,
          value: result.files.first.path!,
        ),
      );
    }
  }

  List<Widget> _buildWrapChildren(List<App> apps) {
    final children = <Widget>[];
    if (!Platform.isAndroid) {
      children.add(
        WrapChild(
          shape: chipBorderRadius,
          text: AppLocalizations.of(context)!.keyword,
          backgroundColor: pinkColorTheme.secondaryContainer,
          foregroundColor: pinkColorTheme.onSecondaryContainer,
        ),
      );
      children.addAll(
        apps
            .where((app) => app.appId.type == AppId_Type.Keyword)
            .map(
              (app) => WrapChild(
                text: app.appId.value,
                shape: chipBorderRadius,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerLow,
                onDelete: () {
                  _setRepo.removeApp([app.id]);
                },
              ),
            ),
      );
      children.add(
        WrapChild(
          text: AppLocalizations.of(context)!.prefix,
          backgroundColor: greenColorTheme.secondaryContainer,
          foregroundColor: greenColorTheme.onSecondaryContainer,
          shape: chipBorderRadius,
        ),
      );
      children.addAll(
        apps
            .where((app) => app.appId.type == AppId_Type.Prefix)
            .map(
              (app) => WrapChild(
                shape: chipBorderRadius,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerLow,
                text: app.appId.value,
                onDelete: () => _setRepo.removeApp([app.id]),
              ),
            ),
      );
    }
    children.add(
      WrapChild(
        shape: chipBorderRadius,
        text: AppLocalizations.of(context)!.exact,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
    children.addAll(
      apps
          .where((app) => app.appId.type == AppId_Type.Exact)
          .map(
            (app) => WrapChild(
              shape: chipBorderRadius,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
              text: app.appId.value,
              onDelete: () => _setRepo.removeApp([app.id]),
            ),
          ),
    );

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final useListview = c.isCompact || Platform.isAndroid;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.addButtonInWrap)
              Row(
                children: [
                  if (widget.showLabel)
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: Chip(
                        side: const BorderSide(color: Colors.transparent),
                        shape: chipBorderRadius,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        label: Text(
                          AppLocalizations.of(context)!.app,
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                  if (!desktopPlatforms)
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(0),
                      onPressed: _onAddApp,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  if (desktopPlatforms) _menuAnchor,
                ],
              ),
            const Gap(10),
            Expanded(
              child: useListview
                  ? Column(
                      children: [
                        if (widget.addButtonInWrap)
                          FilledButton.tonal(
                            onPressed: _onAddApp,
                            child: Text(AppLocalizations.of(context)!.addApp),
                          ),
                        Expanded(
                          child: StreamBuilder(
                            stream: _stream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return ListView.builder(
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (ctx, index) {
                                    final app = snapshot.data!.elementAt(index);
                                    return ListTile(
                                      leading: Platform.isAndroid
                                          ? app.icon == null
                                                ? const Icon(Icons.android)
                                                : Image.memory(app.icon!)
                                          : null,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 5,
                                          ),
                                      title: Text(app.name ?? app.appId.value),
                                      subtitle: Text(
                                        '${app.appId.type.toLocalString(context)}: ${app.appId.value}',
                                      ),
                                      trailing: IconButton(
                                        onPressed: () {
                                          _setRepo.removeApp([app.id]);
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    );
                                  },
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: StreamBuilder(
                        stream: _stream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Wrap(
                              runSpacing: 10,
                              spacing: 10,
                              children: [
                                ..._buildWrapChildren(snapshot.data!),
                                if (widget.addButtonInWrap) _menuAnchor,
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class AddAppIdAndroidScreen extends StatefulWidget {
  const AddAppIdAndroidScreen({
    super.key,
    this.appSetName,
    this.initialAppIds = const [],
  });

  /// When set, selected apps are persisted to this app set via [SetRepo].
  /// When null, [Navigator.pop] returns the selected [AppId]s.
  final String? appSetName;
  final List<AppId> initialAppIds;

  @override
  State<AddAppIdAndroidScreen> createState() => _AddAppIdAndroidScreenState();
}

class _AddAppIdAndroidScreenState extends State<AddAppIdAndroidScreen> {
  final Map<String, SelectedApp> _selectedApps = {};
  List<App> _originalApps = [];
  bool _showSystemApps = false;
  late List<AppInfo> _appInfos;
  List<AppInfo> _filteredAppInfos = [];
  bool _loading = true;
  SetRepo? _setRepo;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _saving = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.appSetName != null) {
      _setRepo = Provider.of<SetRepo>(context, listen: false);
    }
    _searchController.addListener(_onSearchChanged);
    _init();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterApps();
    });
  }

  void _filterApps() {
    if (_searchQuery.isEmpty) {
      _filteredAppInfos = _appInfos;
    } else {
      _filteredAppInfos = _appInfos.where((app) {
        final appName = app.name.toLowerCase();
        final packageName = app.packageName.toLowerCase();
        return appName.contains(_searchQuery) ||
            packageName.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _init() async {
    _appInfos = (await InstalledApps.getInstalledApps(
      !_showSystemApps,
      true,
      "",
    ))..removeWhere((appInfo) => appInfo.packageName == androidPackageNme);
    if (widget.appSetName != null) {
      final value = await _setRepo!.getApps(widget.appSetName!);
      _originalApps = value;
      for (final app in value) {
        _selectedApps[app.appId.value] = (icon: app.icon, name: app.name);
      }
    } else {
      for (final appId in widget.initialAppIds) {
        if (appId.type == AppId_Type.Exact) {
          _selectedApps[appId.value] = (icon: null, name: null);
        }
      }
    }
    setState(() {
      _loading = false;
      _filterApps();
    });
  }

  void _save() async {
    if (widget.appSetName == null) {
      final result = _selectedApps.keys
          .map(
            (packageName) =>
                AppId(type: AppId_Type.Exact, value: packageName),
          )
          .toList();
      if (context.mounted) {
        Navigator.of(context).pop(result);
      }
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      // delete some apps and add some apps
      final toDelete = _originalApps
          .where(
            (app) =>
                app.appId.type == AppId_Type.Exact &&
                !_selectedApps.containsKey(app.appId.value),
          )
          .toList();
      final toAdd = _selectedApps.entries
          .where((e) {
            return !_originalApps.any(
              (app) =>
                  app.appId.type == AppId_Type.Exact &&
                  app.appId.value == e.key,
            );
          })
          .map(
            (e) => App(
              appId: AppId(type: AppId_Type.Exact, value: e.key),
              icon: e.value.icon,
              id: 0,
              appSetName: widget.appSetName!,
              name: e.value.name,
            ),
          )
          .toList();
      if (toDelete.isNotEmpty) {
        await _setRepo!.removeApp(toDelete.map((e) => e.id).toList());
      }
      if (toAdd.isNotEmpty) {
        await _setRepo!.addApps(toAdd);
      }
      unawaited(_maybeUploadCnDirectApps());
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      snack(e.toString());
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _maybeUploadCnDirectApps() async {
    if (!Platform.isAndroid) return;
    if (widget.appSetName != directAppSetName) return;
    if (getUserCountryFromLocale() != 'CN') return;
    final pref = context.read<SharedPreferences>();
    if (!pref.shareCnDirectApps) return;

    final appsByPackage = <String, String?>{};
    for (final entry in _selectedApps.entries) {
      if (entry.key == androidPackageNme) continue;
      appsByPackage[entry.key] = entry.value.name;
    }

    await CnDirectAppsUpload.uploadSnapshot(
      deviceId: pref.uniqueDeviceIdForCnDirectApps,
      appsByPackage: appsByPackage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(AppLocalizations.of(context)!.save),
          ),
          MenuAnchor(
            menuChildren: [
              MenuItemButton(
                onPressed: () async {
                  setState(() {
                    _showSystemApps = !_showSystemApps;
                    _loading = true;
                  });
                  await _init();
                },
                child: Text(
                  _showSystemApps
                      ? AppLocalizations.of(context)!.hideSystemApps
                      : AppLocalizations.of(context)!.showSystemApps,
                ),
              ),
            ],
            builder: (context, controller, child) => IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ),
          const Gap(10),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBar(
                    leading: const Padding(
                      padding: EdgeInsets.zero,
                      child: Icon(Icons.search),
                    ),
                    trailing: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                    ],
                    controller: _searchController,
                    elevation: const WidgetStatePropertyAll(0),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredAppInfos.length,
                    itemBuilder: (context, index) {
                      final app = _filteredAppInfos[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _AppIdTile(
                          key: Key(app.packageName),
                          app: app,
                          selectedApps: _selectedApps,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

typedef SelectedApp = ({Uint8List? icon, String? name});

class _AppIdTile extends StatefulWidget {
  const _AppIdTile({required this.app, required this.selectedApps, super.key});
  final AppInfo app;
  final Map<String, SelectedApp> selectedApps;
  @override
  State<_AppIdTile> createState() => __AppIdTileState();
}

class __AppIdTileState extends State<_AppIdTile> {
  bool _isChecked = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _isChecked = widget.selectedApps.containsKey(widget.app.packageName);
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: AutoSizeText(widget.app.name, maxLines: 1),
      subtitle: Text(widget.app.packageName),
      secondary: widget.app.icon != null
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.memory(widget.app.icon!),
            )
          : const Icon(Icons.android),
      value: _isChecked,
      onChanged: (value) {
        if (value == true) {
          _isChecked = true;
          widget.selectedApps[widget.app.packageName] = (
            icon: widget.app.icon,
            name: widget.app.name,
          );
          // final data = AppsCompanion(
          //   proxy: const Value(false),
          //   appId: Value(AppId(
          //     type: AppId_Type.Exact,
          //     value: widget.app.packageName,
          //   )),
          // );
          // database.into(database.apps).insert(data,
          //     onConflict:
          //         DoUpdate((old) => data, target: [database.apps.appId]));
        } else {
          _isChecked = false;
          widget.selectedApps.remove(widget.app.packageName);
        }
        setState(() {});
      },
    );
  }
}

class AddAppIdDialog extends StatefulWidget {
  const AddAppIdDialog({super.key, required this.appSetName});
  final String appSetName;

  @override
  State<AddAppIdDialog> createState() => _AddAppIdDialogState();
}

class _AddAppIdDialogState extends State<AddAppIdDialog> {
  final TextEditingController _controller = TextEditingController();
  AppId_Type _type = AppId_Type.Keyword;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.add),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 400,
            child: TextField(
              controller: _controller,
              maxLines: 2,
              decoration: InputDecoration(
                helperText: AppLocalizations.of(context)!.caseInsensitive,
                hintText: _type.toHintText(context),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const Gap(12),
          DropdownMenu<AppId_Type>(
            label: Text(AppLocalizations.of(context)!.type),
            initialSelection: _type,
            requestFocusOnTap: false,
            onSelected: (AppId_Type? t) {
              if (t != null) {
                _type = t;
              }
              setState(() {});
            },
            dropdownMenuEntries: AppId_Type.values
                .map(
                  (e) => DropdownMenuEntry(
                    label: e.toLocalString(context),
                    value: e,
                  ),
                )
                .toList(),
          ),
        ],
      ),
      actions: [
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.of(
                context,
              ).pop(AppId(type: _type, value: _controller.text));
            }
          },
          child: Text(AppLocalizations.of(context)!.add),
        ),
      ],
    );
  }
}

class AddAppIdDesktopScreen extends StatefulWidget {
  const AddAppIdDesktopScreen({super.key, required this.appSetName});
  final String appSetName;
  @override
  State<AddAppIdDesktopScreen> createState() => _AddAppIdDesktopScreenState();
}

class _AddAppIdDesktopScreenState extends State<AddAppIdDesktopScreen> {
  final Map<String, SelectedApp> _selectedApps = {};
  List<App> _originalApps = [];
  late List<DesktopAppInfo> _appInfos;
  List<DesktopAppInfo> _filteredAppInfos = [];
  bool _loading = true;
  late SetRepo _setRepo;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _setRepo = Provider.of<SetRepo>(context, listen: false);
    _searchController.addListener(_onSearchChanged);
    _init();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterApps();
    });
  }

  void _filterApps() {
    if (_searchQuery.isEmpty) {
      _filteredAppInfos = _appInfos;
    } else {
      _filteredAppInfos = _appInfos.where((app) {
        final appName = (app.displayName ?? app.name).toLowerCase();
        final execPath = (app.executablePath ?? '').toLowerCase();
        return appName.contains(_searchQuery) ||
            execPath.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _init() async {
    _appInfos = await DesktopInstalledApps.getInstalledApps();
    // Filter out apps without executable paths
    _appInfos = _appInfos
        .where(
          (app) => app.executablePath != null && app.executablePath!.isNotEmpty,
        )
        .toList();

    final value = await _setRepo.getApps(widget.appSetName);
    setState(() {
      _loading = false;
      _originalApps = value;
      for (final app in value) {
        _selectedApps[app.appId.value] = (icon: app.icon, name: app.name);
      }
      _filterApps();
    });
  }

  void _save() async {
    setState(() {
      _saving = true;
    });
    try {
      // delete some apps and add some apps
      final toDelete = _originalApps
          .where(
            (app) =>
                app.appId.type == AppId_Type.Exact &&
                !_selectedApps.containsKey(app.appId.value),
          )
          .toList();
      final toAdd = _selectedApps.entries
          .where((e) {
            return !_originalApps.any(
              (app) =>
                  app.appId.type == AppId_Type.Exact &&
                  app.appId.value == e.key,
            );
          })
          .map(
            (e) => App(
              appId: AppId(type: AppId_Type.Exact, value: e.key),
              icon: e.value.icon,
              id: 0,
              appSetName: widget.appSetName,
              name: e.value.name,
            ),
          )
          .toList();
      if (toDelete.isNotEmpty) {
        await _setRepo.removeApp(toDelete.map((app) => app.id).toList());
      }
      if (toAdd.isNotEmpty) {
        await _setRepo.addApps(toAdd);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Applications'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(AppLocalizations.of(context)!.save),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search applications...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '${_selectedApps.length} selected',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: _filteredAppInfos.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No installed applications found'
                                : 'No apps match your search',
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredAppInfos.length,
                          itemBuilder: (ctx, index) {
                            final app = _filteredAppInfos[index];
                            return _DesktopAppIdTile(
                              app: app,
                              selectedApps: _selectedApps,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _DesktopAppIdTile extends StatefulWidget {
  const _DesktopAppIdTile({required this.app, required this.selectedApps});
  final DesktopAppInfo app;
  final Map<String, SelectedApp> selectedApps;
  @override
  State<_DesktopAppIdTile> createState() => __DesktopAppIdTileState();
}

class __DesktopAppIdTileState extends State<_DesktopAppIdTile> {
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.selectedApps.containsKey(widget.app.executablePath);
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.app.displayName ?? widget.app.name),
      subtitle: Text(widget.app.executablePath ?? ''),
      secondary: const Icon(Icons.desktop_windows),
      value: _isChecked,
      onChanged: (value) {
        final execPath = widget.app.executablePath;
        if (execPath == null) return;

        if (value == true) {
          _isChecked = true;
          widget.selectedApps[execPath] = (icon: null, name: null);
        } else {
          _isChecked = false;
          widget.selectedApps.remove(execPath);
        }
        setState(() {});
      },
    );
  }
}

extension AppIdTypeExtension on AppId_Type {
  String toLocalString(BuildContext context) {
    switch (this) {
      case AppId_Type.Exact:
        return AppLocalizations.of(context)!.exact;
      case AppId_Type.Prefix:
        return AppLocalizations.of(context)!.prefix;
      case AppId_Type.Keyword:
        return AppLocalizations.of(context)!.keyword;
      default:
        return 'Unknown';
    }
  }

  String toHintText(BuildContext context) {
    switch (this) {
      case AppId_Type.Exact:
        if (Platform.isWindows) {
          return "C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe";
        }
        return "/Applications/Docker.app/Contents/MacOS/com.docker.backend";
      case AppId_Type.Prefix:
        if (Platform.isWindows) {
          return "C:\\Program Files\\Docker\\Docker";
        }
        return "/Applications/Google Chrome.app";
      case AppId_Type.Keyword:
        if (Platform.isWindows) {
          return "chrome";
        }
        return "Google";
      default:
        return 'Unknown';
    }
  }
}
