// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Injects a minimal loading spinner into the DOM.
/// Called at the very start of runNinjaApp(), before any async work.
/// Flutter's <flt-glass-pane> is appended to <body> after this div,
/// so it naturally covers the spinner when Flutter paints its first frame —
/// no explicit removal needed.
void insertWebSpinner() {
  final style = html.StyleElement()
    ..text = '''
      #_nsl { position:fixed; inset:0; display:flex; align-items:center; justify-content:center; }
      #_nss { width:32px; height:32px; border-radius:50%; border:3px solid rgba(255,255,255,.15); border-top-color:#fff; animation:_nsp .8s linear infinite; }
      @keyframes _nsp { to { transform:rotate(360deg); } }
    ''';
  html.document.head?.append(style);

  final spinner = html.DivElement()..id = '_nss';
  final wrapper = html.DivElement()
    ..id = '_nsl'
    ..append(spinner);
  html.document.body?.insertBefore(wrapper, html.document.body?.firstChild);
}
