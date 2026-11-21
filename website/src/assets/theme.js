/* Stored color theme, applied before first paint; wires the picker when storage works. */
(function () {
  var KEY = 'scrypath-theme', root = document.documentElement, dark = matchMedia('(prefers-color-scheme: dark)');
  function read() {
    try {
      var v = localStorage.getItem(KEY);
      return v === 'dark' || v === 'system' ? v : 'light';
    } catch (e) { return 'light'; }
  }
  function paint(choice) {
    var meta = document.querySelector('meta[name="theme-color"]');
    root.setAttribute('data-theme', choice);
    if (meta) meta.setAttribute('content', getComputedStyle(root).getPropertyValue('--page').trim());
  }
  paint(read());
  if (dark.addEventListener) dark.addEventListener('change', function () { if (read() === 'system') paint('system'); });
  document.addEventListener('DOMContentLoaded', function () {
    var picker = document.querySelector('.theme-picker'), buttons = picker ? picker.querySelectorAll('[data-theme-choice]') : [], i;
    try {
      localStorage.setItem('scrypath-probe', '1');
      localStorage.removeItem('scrypath-probe');
    } catch (e) { return; }
    if (!picker) return;
    function mark(choice) {
      for (i = 0; i < buttons.length; i++) buttons[i].setAttribute('aria-pressed', String(buttons[i].getAttribute('data-theme-choice') === choice));
    }
    function choose(choice) {
      try { localStorage.setItem(KEY, choice); } catch (e) { /* this page only */ }
      paint(choice);
      mark(choice);
    }
    for (i = 0; i < buttons.length; i++) buttons[i].addEventListener('click', function (e) { choose(e.currentTarget.getAttribute('data-theme-choice')); });
    addEventListener('storage', function (e) { if (e.key === KEY) { paint(read()); mark(read()); } });
    mark(read());
    picker.hidden = false;
  });
})();
