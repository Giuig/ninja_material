// Shared web loading screen for the ninja apps.
//
// Lives in ninja_material and ships to consumers as a package asset, so the
// markup, CSS, animation and theme resolution exist ONCE for the whole fleet.
//
// Each app's web/index.html carries exactly one line, in <head>, NOT async:
//
//   <script src="assets/packages/ninja_material/assets/web/ninja_loader.js"
//           data-prefix="auraninja."
//           data-bg-light="#f9faef"     data-bg-dark="#12140e"
//           data-accent-light="#4b662c" data-accent-dark="#b1d18a"></script>
//
// It must be in <head> and synchronous. A head script blocks first paint, so
// the page's very first paint already carries the right background -- no flash
// to correct afterwards. Loading it in <body>, or with async/defer, means the
// browser paints default white first and this fixes it a frame later, which is
// worse than the problem it solves.
//
// Removal is driven by the app's flutter_bootstrap.js:
//   if (window.ninjaLoader) window.ninjaLoader.hide();
//
// --- Colours ---------------------------------------------------------------
// Preferred source is `loaderPalette`, which bootstrap.dart writes after it
// resolves the real ColorScheme (see _persistLoaderPalette there). That is
// exact, and covers the Material You branch for free, because Flutter has
// already chosen by the time it is written.
//
// The data-* attributes are the FIRST-RUN fallback only: nothing is stored
// until the app has rendered once. Set them to that app's real resolved
// colours rather than guessing -- ColorScheme.fromSeed moves a seed a long way
// (a grey seed lands on cyan), so eyeballed values reproduce exactly the
// mismatch this file exists to remove.
//
// --- Storage ---------------------------------------------------------------
// shared_preferences_web stores in localStorage with plain json.encode, so all
// of this is readable synchronously before any Dart runs. The default key
// prefix is `flutter.`, but every ninja app calls
// `SharedPreferences.setPrefix('<app>.')` on web, because all apps share the
// origin https://giuig.github.io and storage is scoped to the ORIGIN, not the
// path. setPrefix REPLACES `flutter.`, it does not extend it -- hence
// data-prefix, which must match that app's main.dart exactly. Get it wrong and
// the loader silently falls back to defaults rather than failing loudly.

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

  var LABELS = {
    en: 'Loading...',
    de: 'Laden...',
    es: 'Cargando...',
    fr: 'Chargement...',
    it: 'Caricamento...',
    ja: '\u8aad\u307f\u8fbc\u307f\u4e2d...'
  };

  var mode = pref('themeMode');
  var systemDark = false;
  try {
    systemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  } catch (e) { /* matchMedia absent: treat as light */ }

  // themeMode is 'light' | 'dark' | 'system' | null. Anything that is not an
  // explicit override defers to the OS, which mirrors ThemeMode.system.
  var dark = mode === 'dark' || (mode !== 'light' && systemDark);

  var lang = pref('locale');
  if (typeof lang !== 'string' || !LABELS[lang]) {
    // navigator.language is 'it-IT'; the stored key is a bare language code,
    // so take the primary subtag either way.
    lang = ((navigator.language || 'en').split('-')[0] || 'en').toLowerCase();
  }
  var label = d.label || LABELS[lang] || LABELS.en;

  var bg = dark ? (d.bgDark || '#131316') : (d.bgLight || '#faf9fd');
  var primary = dark ? (d.accentDark || '#b3c5ff') : (d.accentLight || '#4a5c92');
  var secondary = primary;
  var outline = primary;
  var exact = false;

  // setString stores a JSON string and shared_preferences json-encodes it
  // again, so the stored value is JSON inside JSON. pref() unwraps one layer
  // and leaves a string; this parses the second.
  var rawPalette = pref('loaderPalette');
  if (typeof rawPalette === 'string') {
    try {
      var pal = JSON.parse(rawPalette);
      var side = dark ? pal.d : pal.l;
      if (side && side.p) {
        primary = side.p;
        secondary = side.s || side.p;
        bg = side.b || bg;
        outline = side.o || side.p;
        exact = true;
      }
    } catch (e) { /* malformed: keep the data-* fallback */ }
  }

  var css =
    'html,body{margin:0;padding:0;height:100%}' +
    'body{background:' + bg + '}' +
    '#' + id + '{position:fixed;inset:0;display:flex;flex-direction:column;' +
    'align-items:center;justify-content:center;overflow:hidden;' +
    'gap:clamp(12px,3vmin,26px);background:' + bg + ';' +
    'font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;' +
    'opacity:1;transition:opacity .25s ease-out}' +
    '#' + id + '.ninja-hide{opacity:0;pointer-events:none}' +

    // Sized in vmin so it scales with whatever viewport it is in. Inside an
    // iframe vmin resolves against the IFRAME's viewport, so an embedded app
    // is handled without the loader knowing it is embedded.
    '#' + id + ' .ninja-star{width:clamp(56px,18vmin,124px);' +
    'height:clamp(56px,18vmin,124px);position:relative;z-index:2;' +
    'animation:ninja-rot 1.6s linear infinite}' +
    '#' + id + ' .ninja-blade{fill:' + primary + '}' +
    '#' + id + ' .ninja-hub{fill:' + bg + '}' +
    '#' + id + ' .ninja-label{color:' + primary + ';position:relative;z-index:2;' +
    'font-size:clamp(13px,3vmin,19px);letter-spacing:.04em;opacity:.7}' +
    '@keyframes ninja-rot{to{transform:rotate(360deg)}}' +

    // Wind: purely horizontal, right to left, tightly staggered. Only
    // transform and opacity animate, so this stays on the compositor rather
    // than competing with the main thread while it parses main.dart.js.
    '#' + id + ' .ninja-fx{position:absolute;inset:0;pointer-events:none;z-index:1}' +
    '#' + id + ' .ninja-fx i{position:absolute;right:-16%;height:2px;' +
    'border-radius:2px;background:' + outline + ';opacity:0;' +
    'animation:ninja-gust 1.15s linear infinite}' +
    '#' + id + ' .ninja-fx svg{position:absolute;right:-8%;' +
    'width:clamp(11px,2.6vmin,18px);height:clamp(11px,2.6vmin,18px);' +
    'opacity:0;animation:ninja-blow 1.7s linear infinite}' +
    '#' + id + ' .ninja-fx svg path{fill:' + secondary + '}' +
    '@keyframes ninja-gust{0%{transform:translateX(0);opacity:0}' +
    '15%{opacity:.8}75%{opacity:.5}100%{transform:translateX(-135vw);opacity:0}}' +
    '@keyframes ninja-blow{0%{transform:translateX(0) rotate(0);opacity:0}' +
    '12%{opacity:.9}55%{transform:translateX(-60vw) rotate(260deg)}' +
    '100%{transform:translateX(-125vw) rotate(520deg);opacity:0}}' +

    // Reduced motion: drop the weather entirely and stop the star, leaving a
    // clean static mark rather than a slower version of the same thing.
    '@media(prefers-reduced-motion:reduce){#' + id + ' .ninja-fx{display:none}' +
    '#' + id + ' *{animation:none!important}#' + id + '{transition:none}}';

  var style = document.createElement('style');
  style.textContent = css;
  (document.head || document.documentElement).appendChild(style);

  // [top%, animation-delay s, width%] -- A's flat layout at E's stagger.
  var GUSTS = [
    [18, 0, 13], [30, 0.06, 7], [44, 0.12, 11], [58, 0.18, 6],
    [70, 0.24, 10], [82, 0.3, 5], [8, 0.36, 9]
  ];
  var LEAVES = [[26, 0.15], [60, 0.6], [40, 1.05], [74, 1.5]];
  var LEAF = 'M8 1 C13 4 14 10 8 15 C2 10 3 4 8 1 Z';

  function build() {
    if (document.getElementById(id)) return;
    var fx = '';
    var i;
    for (i = 0; i < GUSTS.length; i++) {
      fx += '<i style="top:' + GUSTS[i][0] + '%;animation-delay:' + GUSTS[i][1] +
            's;width:' + GUSTS[i][2] + '%"></i>';
    }
    for (i = 0; i < LEAVES.length; i++) {
      fx += '<svg viewBox="0 0 16 16" style="top:' + LEAVES[i][0] +
            '%;animation-delay:' + LEAVES[i][1] + 's"><path d="' + LEAF + '"/></svg>';
    }

    var el = document.createElement('div');
    el.id = id;
    el.innerHTML =
      '<div class="ninja-fx" aria-hidden="true">' + fx + '</div>' +
      '<svg class="ninja-star" viewBox="0 0 48 48" aria-hidden="true">' +
      '<path class="ninja-blade" d="M24 2 L30 18 L46 24 L30 30 L24 46 L18 30 L2 24 L18 18 Z"/>' +
      '<circle class="ninja-hub" cx="24" cy="24" r="4.5"/></svg>' +
      '<div class="ninja-label">' + label + '</div>';
    document.body.insertBefore(el, document.body.firstChild);
  }

  // In <head> there is no body yet, so the element waits for the parser. The
  // stylesheet above is already applied, so first paint is the right colour
  // either way.
  if (document.body) build();
  else document.addEventListener('DOMContentLoaded', build);

  window.ninjaLoader = {
    resolved: {
      dark: dark, primary: primary, secondary: secondary, outline: outline,
      background: bg, prefix: prefix, lang: lang, label: label, exact: exact
    },
    hide: function () {
      var el = document.getElementById(id);
      if (!el) return;

      // Read the real transition duration rather than assuming one. Under
      // prefers-reduced-motion the transition is `none`, so `transitionend`
      // never fires -- with a hardcoded fallback timer that made the loader
      // linger after the app was already up, for precisely the users who
      // asked for less motion. Zero duration means remove now.
      var ms = 0;
      try {
        var v = getComputedStyle(el).transitionDuration || '0s';
        // Can be a comma-separated list; the longest one governs.
        ms = Math.max.apply(null, v.split(',').map(function (x) {
          x = x.trim();
          var n = parseFloat(x) || 0;
          return x.indexOf('ms') > -1 ? n : n * 1000;
        }));
      } catch (e) { ms = 0; }

      if (!ms) {
        el.remove();
        return;
      }

      el.addEventListener('transitionend', function () { el.remove(); }, { once: true });
      el.classList.add('ninja-hide');
      // Safety net only, in case transitionend is missed (interrupted
      // transition, backgrounded tab). Derived from the real duration, not a
      // fixed number, so it can never outlive the animation it guards.
      setTimeout(function () { el.remove(); }, ms + 80);
    }
  };
})();
