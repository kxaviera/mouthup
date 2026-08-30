import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mouthup_logo.dart';

/// Wraps routed content in a centered phone frame when running on web.
class MobileFrame extends StatelessWidget {
  const MobileFrame({super.key, required this.child});

  final Widget child;

  static const double phoneWidth = 390;
  static const double phoneHeight = 844;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    const framePadding = 14.0;
    const outerRadius = 46.0;
    const innerRadius = 34.0;
    const outerW = phoneWidth + framePadding * 2;
    const outerH = phoneHeight + framePadding * 2;

    return ColoredBox(
      color: const Color(0xFF000000),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IsziWordmark(height: 20),
                const SizedBox(height: 4),
                const Text(
                  'Mobile preview • 390 × 844',
                  style: TextStyle(color: Color(0xFF555555), fontSize: 11),
                ),
                const SizedBox(height: 16),
                Container(
                  width: outerW,
                  height: outerH,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(outerRadius),
                    border: Border.all(color: const Color(0xFF333333)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 60,
                        offset: Offset(0, 24),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(framePadding),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(innerRadius),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: phoneWidth,
                          height: phoneHeight,
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              size: const Size(phoneWidth, phoneHeight),
                              padding: const EdgeInsets.only(top: 12, bottom: 8),
                            ),
                            child: child,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 110,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF222222)),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 120,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
