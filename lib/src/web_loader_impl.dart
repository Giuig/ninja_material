import 'package:web/web.dart';

/// Injects a minimal loading spinner into the DOM.
///
/// Called at the very start of `runNinjaApp()`, before any async work.
/// Flutter's `<flt-glass-pane>` is appended to `<body>` after this div, so it
/// naturally covers the spinner when Flutter paints its first frame — no
/// explicit removal needed.
///
/// Uses `package:web` rather than `dart:html`, which is deprecated and will
/// eventually stop compiling rather than merely warning.
void insertWebSpinner() {
  final style = document.createElement('style') as HTMLStyleElement;
  style.textContent = '''
      #_nsl { position:fixed; inset:0; display:flex; align-items:center; justify-content:center; }
      #_nss { width:32px; height:32px; border-radius:50%; border:3px solid rgba(255,255,255,.15); border-top-color:#fff; animation:_nsp .8s linear infinite; }
      @keyframes _nsp { to { transform:rotate(360deg); } }
    ''';
  document.head?.appendChild(style);

  final spinner = document.createElement('div') as HTMLDivElement;
  spinner.id = '_nss';

  final wrapper = document.createElement('div') as HTMLDivElement;
  wrapper.id = '_nsl';
  wrapper.appendChild(spinner);

  document.body?.insertBefore(wrapper, document.body?.firstChild);
}
