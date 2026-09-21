// Custom Flutter web bootstrap for the ninja apps.
//
// Adding this file makes Flutter use it INSTEAD of the one it generates, so
// the two template tokens below are mandatory. Drop either one and you get a
// build that silently never boots.
//
// !! Do NOT write the token names with their double braces anywhere else in
// !! this file, not even inside a comment. Flutter does a literal textual
// !! find-and-replace, so a token mentioned in a comment is ALSO expanded --
// !! flutter.js is multi-line, so line 1 stays commented and every line after
// !! it becomes live, broken JS. Symptom: "Uncaught SyntaxError: Unexpected
// !! identifier", the loader never clears, and main.dart.js is never even
// !! requested. Checking that no unexpanded braces remain does not catch this,
// !! because the stray copy expanded too.
//
// The only thing this adds over the default is the onEntrypointLoaded hook,
// which lets us dismiss the HTML loader in index.html at a precise moment
// rather than relying on Flutter's host element happening to cover it.

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    // Engine is initialised but has not painted yet.
    const engine = await engineInitializer.initializeEngine();

    const loader = document.getElementById('ninja-loader');
    if (loader) {
      // Remove on transitionend rather than a fixed timeout, so this stays
      // correct when prefers-reduced-motion disables the transition.
      loader.addEventListener('transitionend', () => loader.remove(), { once: true });
      loader.classList.add('ninja-hide');
      // Fallback: with no transition, transitionend never fires.
      setTimeout(() => loader.remove(), 400);
    }

    await engine.runApp();
  }
});
