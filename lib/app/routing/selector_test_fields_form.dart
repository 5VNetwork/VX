import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:vx/l10n/app_localizations.dart';

String? _validateUint32(AppLocalizations l10n, String value) {
  if (value.trim().isEmpty) return l10n.fieldRequired;
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed < 0) {
    return l10n.selectorTestMustBeNonNegativeInteger;
  }
  if (parsed > 0xFFFFFFFF) return l10n.selectorTestMustBeAtMostUint32Max;
  return null;
}

// [config] is not edited directly. A new config is returned
Future<SelectorConfig?> showSelectorTestFieldsForm(
  BuildContext context,
  SelectorConfig config,
) async {
  if (config.speedTestSize == 0) {
    config.speedTestSize = 1000000;
  }
  if (config.speedTestInterval == 0) {
    config.speedTestInterval = 60;
  }
  if (config.pingTestInterval == 0) {
    config.pingTestInterval = 10;
  }
  if (config.unusableTestInterval == 0) {
    config.unusableTestInterval = 10;
  }
  final speedTestSizeController = TextEditingController(
    text: config.speedTestSize.toString(),
  );
  final speedTestIntervalController = TextEditingController(
    text: config.speedTestInterval.toString(),
  );
  final pingTestIntervalController = TextEditingController(
    text: config.pingTestInterval.toString(),
  );
  final unusableTestIntervalController = TextEditingController(
    text: config.unusableTestInterval.toString(),
  );

  try {
    return await showDialog<SelectorConfig>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        String? speedSizeError;
        String? speedIntervalError;
        String? pingIntervalError;
        String? unusableIntervalError;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.selectorTestFieldsTitle(config.tag)),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: speedTestSizeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.selectorTestSpeedTestSizeLabel,
                          suffixText: l10n.selectorTestByteSuffix,
                          helperText: l10n.selectorTestSpeedTestSizeHelper,
                          hintText: '1000000',
                          errorText: speedSizeError,
                          hintMaxLines: 5,
                        ),
                      ),
                      const Gap(10),
                      TextField(
                        controller: speedTestIntervalController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.selectorTestSpeedTestIntervalLabel,
                          suffixText: l10n.selectorTestMinutesSuffix,
                          helperText:
                              l10n.selectorTestSpeedTestIntervalHelper,
                          helperMaxLines: 2,
                          errorText: speedIntervalError,
                        ),
                      ),
                      const Gap(10),
                      TextField(
                        controller: pingTestIntervalController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.selectorTestPingTestIntervalLabel,
                          suffixText: l10n.selectorTestMinutesSuffix,
                          helperText:
                              l10n.selectorTestPingTestIntervalHelper,
                          helperMaxLines: 2,
                          errorText: pingIntervalError,
                        ),
                      ),
                      const Gap(10),
                      TextField(
                        controller: unusableTestIntervalController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText:
                              l10n.selectorTestUnusableTestIntervalLabel,
                          suffixText: l10n.selectorTestMinutesSuffix,
                          helperText:
                              l10n.selectorTestUnusableTestIntervalHelper,
                          helperMaxLines: 2,
                          errorText: unusableIntervalError,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
                ),
                FilledButton(
                  onPressed: () {
                    final speedSizeErr = _validateUint32(
                      l10n,
                      speedTestSizeController.text,
                    );
                    final speedIntervalErr = _validateUint32(
                      l10n,
                      speedTestIntervalController.text,
                    );
                    final pingIntervalErr = _validateUint32(
                      l10n,
                      pingTestIntervalController.text,
                    );
                    final unusableIntervalErr = _validateUint32(
                      l10n,
                      unusableTestIntervalController.text,
                    );
                    final hasError =
                        speedSizeErr != null ||
                        speedIntervalErr != null ||
                        pingIntervalErr != null ||
                        unusableIntervalErr != null;
                    if (hasError) {
                      setState(() {
                        speedSizeError = speedSizeErr;
                        speedIntervalError = speedIntervalErr;
                        pingIntervalError = pingIntervalErr;
                        unusableIntervalError = unusableIntervalErr;
                      });
                      return;
                    }

                    final copy = config.deepCopy();
                    copy.speedTestSize = int.parse(
                      speedTestSizeController.text.trim(),
                    );
                    copy.speedTestInterval = int.parse(
                      speedTestIntervalController.text.trim(),
                    );
                    copy.pingTestInterval = int.parse(
                      pingTestIntervalController.text.trim(),
                    );
                    copy.unusableTestInterval = int.parse(
                      unusableTestIntervalController.text.trim(),
                    );
                    Navigator.of(ctx).pop(copy);
                  },
                  child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    speedTestSizeController.dispose();
    speedTestIntervalController.dispose();
    pingTestIntervalController.dispose();
    unusableTestIntervalController.dispose();
  }
}
