// Shared web loading screen for the ninja apps.
//
// Lives in ninja_material and ships to consumers as a package asset, so the
// markup, CSS, animation and theme resolution exist ONCE for the whole fleet.
//
// Each app's web/index.html carries exactly one line, in <head>, NOT async:
//
//   <script src="assets/packages/ninja_material/assets/web/ninja_loader.js"
//           data-prefix="auraninja."
//           data-bg-light="#faf9fd"     data-bg-dark="#131316"
//           data-accent-light="#4a5c92" data-accent-dark="#b3c5ff"></script>
//
// It must be in <head> and synchronous. A head script blocks first paint, so
// the page's very first paint already carries the right background — no flash
// to correct afterwards. Loading it in <body>, or with async/defer, means the
// browser paints default white first and this fixes it a frame later, which is
// worse than the problem it solves.
//
// Removal is driven by the app's flutter_bootstrap.js:
//   if (window.ninjaLoader) window.ninjaLoader.hide();
//
// --- Theme awareness -------------------------------------------------------
// Reads the user's real stored theme so the loader matches the app that is
// about to appear, rather than the app's compiled-in default.
//
// shared_preferences_web 2.4.3 stores in localStorage with plain json.encode,
// so these are readable synchronously before any Dart runs. The default key
// prefix is `flutter.`, but every ninja app calls
// `SharedPreferences.setPrefix('<app>.')` on web, because all apps share the
// origin https://giuig.github.io and storage is scoped to the ORIGIN, not the
// path. setPrefix REPLACES `flutter.`, it does not extend it — hence
// data-prefix, which must match that app's main.dart exactly. Get it wrong and
// the loader silently falls back to defaults rather than failing loudly.
//
// The data-* colours remain the first-run fallback: nothing is stored until
// the user actually changes a setting.

(function () {
  var s = document.currentScript;
  var d = (s && s.dataset) || {};
  var prefix = d.prefix || 'flutter.';
  var id = 'ninja-loader';

  function pref(key) {
    try {
      var raw = localStorage.getItem(prefix + key);
      return raw === null ? null : JSON.parse(raw);
    } catch (e) {
      // Private mode, blocked storage, or malformed value: fall back.
      return null;
    }
  }

  var mode = pref('themeMode');
  var systemDark = false;
  try {
    systemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  } catch (e) { /* matchMedia absent: treat as light */ }

  // themeMode is 'light' | 'dark' | 'system' | null. Anything that is not an
  // explicit override defers to the OS, which mirrors ThemeMode.system.
  var dark = mode === 'dark' || (mode !== 'light' && systemDark);

  var bg = dark ? (d.bgDark || '#131316') : (d.bgLight || '#faf9fd');
  var accent = dark ? (d.accentDark || '#b3c5ff') : (d.accentLight || '#4a5c92');

  // customAccentColor is stored as an ARGB int (Color.toARGB32). It is the
  // SEED Flutter feeds to ColorScheme.fromSeed, not the tone it finally
  // renders, so this is close rather than identical - near enough that there
  // is no visible jump at handover.
  var argb = pref('customAccentColor');
  if (typeof argb === 'number' && isFinite(argb)) {
    accent = '#' + (argb & 0xFFFFFF).toString(16).padStart(6, '0');
  }

  var css =
    'html,body{margin:0;padding:0;height:100%}' +
    'body{background:' + bg + '}' +
    '#' + id + '{position:fixed;inset:0;display:flex;flex-direction:column;' +
    'align-items:center;justify-content:center;gap:18px;background:' + bg + ';' +
    'font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;' +
    'opacity:1;transition:opacity .25s ease-out}' +
    '#' + id + '.ninja-hide{opacity:0;pointer-events:none}' +
    // Shuriken: eased rather than linear rotation, so each turn reads as a
    // wind-up and release (a thrown star) instead of a machine spinning.
    '#' + id + ' svg{width:46px;height:46px;' +
    'animation:ninja-rot 2.4s cubic-bezier(.6,0,.4,1) infinite}' +
    '#' + id + ' .ninja-blade{fill:' + accent + '}' +
    '#' + id + ' .ninja-hub{fill:' + bg + '}' +
    '#' + id + ' .ninja-label{color:' + accent + ';font-size:13px;' +
    'letter-spacing:.04em;opacity:.7}' +
    '@keyframes ninja-rot{to{transform:rotate(360deg)}}' +
    '@media(prefers-reduced-motion:reduce){#' + id + ' *{animation:none!important}' +
    '#' + id + '{transition:none}}';

  var style = document.createElement('style');
  style.textContent = css;
  (document.head || document.documentElement).appendChild(style);

  function build() {
    if (document.getElementById(id)) return;
    var el = document.createElement('div');
    el.id = id;
    el.innerHTML =
      '<svg viewBox="0 0 48 48" aria-hidden="true">' +
      '<path class="ninja-blade" d="M24 2 L30 18 L46 24 L30 30 L24 46 L18 30 L2 24 L18 18 Z"/>' +
      '<circle class="ninja-hub" cx="24" cy="24" r="4.5"/></svg>' +
      '<div class="ninja-label">' + (d.label || 'Loading…') + '</div>';
    document.body.insertBefore(el, document.body.firstChild);
  }

  // In <head> there is no body yet, so the element waits for the parser. The
  // stylesheet above is already applied, so first paint is the right colour
  // either way.
  if (document.body) build();
  else document.addEventListener('DOMContentLoaded', build);

  window.ninjaLoader = {
    resolved: { dark: dark, accent: accent, background: bg, prefix: prefix },
    hide: function () {
      var el = document.getElementById(id);
      if (!el) return;
      el.addEventListener('transitionend', function () { el.remove(); }, { once: true });
      el.classList.add('ninja-hide');
      setTimeout(function () { el.remove(); }, 400);
    }
  };
})();
