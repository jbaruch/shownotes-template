/**
 * Skill install copy control (feature 002-talk-skill-section)
 *
 * Progressive enhancement for the "Copy" button next to the install command:
 * - Feature-detects the async Clipboard API; when it is unavailable (insecure
 *   context, old browser) the buttons are hidden and the command stays
 *   selectable as plain text.
 * - Success and failure are written to an aria-live status element so
 *   assistive technology announces them.
 * - No dependencies, no global state, no animation.
 */
(function () {
  'use strict';

  var SUCCESS_TEXT = 'Copied to clipboard';
  var FAILURE_TEXT = 'Copy failed. Select the command and copy it manually.';
  var CLEAR_AFTER_MS = 2000;

  function clipboardAvailable() {
    return !!(navigator.clipboard && typeof navigator.clipboard.writeText === 'function');
  }

  function statusElementFor(button) {
    var id = button.getAttribute('aria-describedby');
    return id ? document.getElementById(id) : null;
  }

  function setStatus(element, text, clear) {
    if (!element) {
      return;
    }
    element.textContent = text;
    if (clear) {
      window.setTimeout(function () {
        if (element.textContent === text) {
          element.textContent = '';
        }
      }, CLEAR_AFTER_MS);
    }
  }

  function wire(button) {
    var target = document.getElementById(button.getAttribute('data-copy-target'));
    var status = statusElementFor(button);
    if (!target) {
      button.hidden = true;
      return;
    }
    button.addEventListener('click', function () {
      navigator.clipboard.writeText(target.textContent.trim()).then(
        function () { setStatus(status, SUCCESS_TEXT, true); },
        function () { setStatus(status, FAILURE_TEXT, false); }
      );
    });
  }

  function init() {
    var buttons = document.querySelectorAll('[data-copy-target]');
    var available = clipboardAvailable();
    Array.prototype.forEach.call(buttons, function (button) {
      if (available) {
        wire(button);
      } else {
        button.hidden = true;
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
