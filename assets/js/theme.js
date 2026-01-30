/**
 * Theme Toggle Script - FR-014, FR-016, FR-017
 *
 * Features:
 * - Detects system preference (prefers-color-scheme)
 * - Persists user choice in localStorage
 * - Graceful degradation when localStorage unavailable (private browsing)
 * - Keyboard accessible (Enter/Space)
 * - No flash of wrong theme (handled by inline script in <head>)
 */
(function() {
  'use strict';

  var STORAGE_KEY = 'theme';
  var DARK = 'dark';
  var LIGHT = 'light';

  /**
   * Check if localStorage is available (FR-017)
   * Returns false in private browsing mode
   */
  function isStorageAvailable() {
    try {
      var test = '__storage_test__';
      localStorage.setItem(test, test);
      localStorage.removeItem(test);
      return true;
    } catch (e) {
      return false;
    }
  }

  var storageAvailable = isStorageAvailable();

  /**
   * Get the preferred theme
   * Priority: localStorage > system preference > light (default)
   */
  function getPreferredTheme() {
    if (storageAvailable) {
      var stored = localStorage.getItem(STORAGE_KEY);
      if (stored === DARK || stored === LIGHT) {
        return stored;
      }
    }
    // Fall back to system preference
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return DARK;
    }
    return LIGHT;
  }

  /**
   * Apply theme to document
   */
  function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);

    // Persist to localStorage if available (FR-016)
    if (storageAvailable) {
      try {
        localStorage.setItem(STORAGE_KEY, theme);
      } catch (e) {
        // Silently fail if storage is full or blocked (FR-017)
      }
    }

    // Update aria-label for accessibility
    var toggle = document.getElementById('theme-toggle');
    if (toggle) {
      toggle.setAttribute('aria-label',
        theme === DARK ? 'Switch to light mode' : 'Switch to dark mode'
      );
    }
  }

  /**
   * Toggle between light and dark themes
   */
  function toggleTheme() {
    var current = document.documentElement.getAttribute('data-theme');
    setTheme(current === DARK ? LIGHT : DARK);
  }

  /**
   * Initialize theme toggle button
   */
  function initToggleButton() {
    var toggle = document.getElementById('theme-toggle');
    if (!toggle) return;

    // Click handler
    toggle.addEventListener('click', function(e) {
      e.preventDefault();
      toggleTheme();
    });

    // Keyboard handler (FR-016: Enter/Space)
    toggle.addEventListener('keydown', function(e) {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        toggleTheme();
      }
    });
  }

  /**
   * Listen for system preference changes
   * Only applies if user hasn't set a manual preference
   */
  function initSystemPreferenceListener() {
    if (!window.matchMedia) return;

    var mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

    // Modern browsers
    if (mediaQuery.addEventListener) {
      mediaQuery.addEventListener('change', function(e) {
        // Only auto-switch if no stored preference
        if (!storageAvailable || !localStorage.getItem(STORAGE_KEY)) {
          setTheme(e.matches ? DARK : LIGHT);
        }
      });
    }
  }

  // Apply theme immediately (backup for inline script)
  var currentTheme = document.documentElement.getAttribute('data-theme');
  if (!currentTheme) {
    setTheme(getPreferredTheme());
  }

  // Set up toggle button when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initToggleButton);
  } else {
    initToggleButton();
  }

  // Listen for system preference changes
  initSystemPreferenceListener();

})();
