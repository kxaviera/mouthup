import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pops the route stack when possible; otherwise navigates to [fallback].
void popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
