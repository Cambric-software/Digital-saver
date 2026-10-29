// The download page has no build step and no dependencies.
//
// The version chip is shown only when a real version is supplied, either as
// ?version=1.2.3 or by setting data-version on <body>. Until then the page says
// nothing about a version rather than printing a hard-coded one that will go
// stale.
(function () {
  'use strict';

  var params = new URLSearchParams(window.location.search);
  var version = params.get('version') || document.body.dataset.version || '';
  var line = document.getElementById('version-line');
  var value = document.getElementById('version-value');

  if (version && line && value) {
    value.textContent = version.charAt(0) === 'v' ? version : 'v' + version;
    line.hidden = false;
  }

  var year = document.getElementById('year');
  if (year) {
    year.textContent = String(new Date().getFullYear());
  }
})();
