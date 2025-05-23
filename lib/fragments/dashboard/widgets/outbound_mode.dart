import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/providers/config.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class OutboundMode extends StatelessWidget {
  const OutboundMode({super.key});

  @override
  Widget build(BuildContext context) {
    final height = getWidgetHeight(2);
    return SizedBox(
      height: height,
      child: Consumer(
        builder: (_, ref, __) {
          final mode =
              ref.watch(patchClashConfigProvider.select((state) => state.mode));
          return CommonCard(
            onPressed: () {},
            info: Info(
              label: appLocalizations.outboundMode,
              iconData: Icons.call_split_sharp,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (final item in Mode.values)
                    Flexible(
                      child: ListItem.radio(
                        dense: true,
                        horizontalTitleGap: 4,
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 16,
                        ),
                        delegate: RadioDelegate(
                          value: item,
                          groupValue: mode,
                          onChanged: (value) async {
                            if (value == null) {
                              return;
                            }
                            globalState.appController.changeMode(value);
                          },
                        ),
                        title: Text(
                          Intl.message(item.name),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.toSoftBold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
