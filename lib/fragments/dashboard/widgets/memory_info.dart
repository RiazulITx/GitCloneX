import 'dart:async';
import 'dart:io';

import 'package:errorx/clash/clash.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/models/common.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';

final _memoryInfoStateNotifier = ValueNotifier<TrafficValue>(
  TrafficValue(value: 0),
);

class MemoryInfo extends StatefulWidget {
  const MemoryInfo({super.key});

  @override
  State<MemoryInfo> createState() => _MemoryInfoState();
}

class _MemoryInfoState extends State<MemoryInfo> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _updateMemory();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  _updateMemory() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final rss = ProcessInfo.currentRss;
      _memoryInfoStateNotifier.value = TrafficValue(
        value: clashLib != null ? rss : await clashCore.getMemory() + rss,
      );
      timer = Timer(Duration(seconds: 2), () async {
        _updateMemory();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(
          iconData: Icons.memory,
          label: appLocalizations.memoryInfo,
        ),
        onPressed: () {
          clashCore.requestGc();
        },
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: _memoryInfoStateNotifier,
              builder: (_, trafficValue, __) {
                return Padding(
                  padding: baseInfoEdgeInsets.copyWith(
                    bottom: 0,
                    top: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        trafficValue.showValue,
                        style:
                            context.textTheme.bodyMedium?.toLight.adjustSize(1),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Text(
                        trafficValue.showUnit,
                        style:
                            context.textTheme.bodyMedium?.toLight.adjustSize(1),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// class AnimatedCounter extends StatefulWidget {
//   final double value;
//   final TextStyle? style;
//
//   const AnimatedCounter({
//     super.key,
//     required this.value,
//     this.style,
//   });
//
//   @override
//   State<AnimatedCounter> createState() => _AnimatedCounterState();
// }
//
// class _AnimatedCounterState extends State<AnimatedCounter> {
//   late double _previousValue;
//   late double _currentValue;
//
//   @override
//   void initState() {
//     super.initState();
//     _previousValue = widget.value;
//     _currentValue = widget.value;
//   }
//
//   @override
//   void didUpdateWidget(AnimatedCounter oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.value != widget.value) {
//       // if (_previousValue == _currentValue) {
//       //   _previousValue = widget.value;
//       //   _currentValue = widget.value;
//       //   return;
//       // }
//       _currentValue = widget.value;
//     }
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       _currentValue.fixed(decimals: 1),
//       style: widget.style,
//     );
//     return TweenAnimationBuilder(
//       tween: Tween(
//         begin: _previousValue,
//         end: _currentValue,
//       ),
//       onEnd: () {
//         _previousValue = _currentValue;
//       },
//       duration: Duration(seconds: 6),
//       curve: Curves.easeOut,
//       builder: (_, value, ___) {
//         return Text(
//           value.fixed(decimals: 1),
//           style: widget.style,
//         );
//       },
//     );
//   }
// }
