/*
 * Modifier settings
 */

// 224 = Meta, which is the Command key on OS X
// 91 = Super; https://bugzilla.mozilla.org/show_bug.cgi?id=751750
user_pref("ui.key.accelKey", 91);

// Alt as menu prefix conflicts with emacs bindings in text fields
user_pref("ui.key.menuAccessKey", 0);
user_pref("ui.key.menuAccessKeyFocuses", false);

// If generalAccessKey is -1, use the following two prefs instead.
// Use 0 for disabled, 1 for Shift, 2 for Ctrl, 4 for Alt, 8 for Meta (Cmd)
// (values can be combined, e.g. 3 for Ctrl+Shift)
user_pref("ui.key.generalAccessKey", -1);
user_pref("ui.key.chromeAccess", 0);
user_pref("ui.key.contentAccess", 0);

/*
 * Fonts
 */

user_pref("font.default.x-western", "sans-serif");
user_pref("font.name.monospace.x-western", "Consolas");
user_pref("font.name.sans-serif.x-western", "Segoe UI");
user_pref("font.name.serif.x-western", "Adobe Caslon Pro");
user_pref("font.size.fixed.x-western", 16);

/*
 * Preferences
 */

// Keep window open when closing last tab
user_pref("browser.tabs.closeWindowWithLastTab", false);

// Disable site-specific zoom
user_pref("browser.zoom.siteSpecific", false);

// Disable warnings
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.tabs.warnOnCloseOtherTabs", false);
user_pref("browser.tabs.warnOnOpen", false);
user_pref("browser.warnOnQuit", false);

// Set blank homepage
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.startup.page", 0);

// Disable Firefox Home screen features
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeBookmarks", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeDownloads", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includePocket", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeVisited", false);
user_pref("browser.newtabpage.activity-stream.showSearch", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);

// Disable search suggestions
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.openpage", false);

// Disable "Recommend extensions as you browse"
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);

// Disable "Recommend features as you browse"
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);

// Enable strict tracking protection
user_pref("browser.contentblocking.category", "strict");

// Disable password manager
user_pref("signon.rememberSignons", false);

// Disable accessibility services
user_pref("accessibility.force_disabled", 1);

// Disable telemetry
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("browser.chrome.errorReporter.enabled", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit", false);
user_pref("browser.discovery.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.cachedClientID", "");
user_pref("toolkit.telemetry.enabled", false);

// Prevent WebRTC from leaking local IP addresses
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("media.peerconnection.ice.no_host", true);
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);

// Disable pre-fetching
user_pref("network.dns.disablePrefetch", true);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("network.predictor.enabled", false);
user_pref("network.prefetch-next", false);

// Disable dynamic malware blocklists
user_pref("browser.safebrowsing.blockedURIs.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.block_dangerous", false);
user_pref("browser.safebrowsing.downloads.remote.block_dangerous_host", false);
user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);

// Disable OCSP
user_pref("security.OCSP.enabled", 0);

// Devtools dark theme
user_pref("devtools.theme", "dark");

// Set browser UI to compact
user_pref("browser.uidensity", 1);

// Disable automatic updates
user_pref("app.update.auto", false);
user_pref("app.update.enabled", false);

// Disable automatic searchplugin updates
user_pref("browser.search.update", false);

// Disable automatic extension updates
user_pref("extensions.update.autoUpdateDefault", false);

// Disable autofill
user_pref("extensions.formautofill.addresses.enabled", false);

// Disable Geolocation
user_pref("geo.enabled", false);

// Disable checkerboard recording
user_pref("apz.record_checkerboarding", false);

// Disable restore session after crash
user_pref("browser.sessionstore.resume_from_crash", false);

// Never store extra session data
user_pref("browser.sessionstore.privacy_level", 2);

// Disable Pocket
user_pref("extensions.pocket.enabled", false);

// Disable clipboard events
user_pref("dom.event.clipboardevents.enabled", false);

// Show non-ASCII domains as punycode
user_pref("network.IDN_show_punycode", true);

// Disable screenshot uploading
user_pref("extensions.screenshots.upload-disabled", false);

// Disable builtin DNS resolver
user_pref("network.trr.mode", 5);

// Enable userChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Disable captive portal detection
user_pref("captivedetect.maxRetryCount", 0);
user_pref("captivedetect.maxWaitingTime", 0);
user_pref("captivedetect.pollingTime", 0);
user_pref("captivedetect.canonicalURL", "");

// Disable network connectivity detection
user_pref("network.connectivity-service.DNSv4.domain", "");
user_pref("network.connectivity-service.DNSv6.domain", "");
user_pref("network.connectivity-service.IPv4.url", "");
user_pref("network.connectivity-service.IPv6.url", "");
user_pref("network.connectivity-service.enabled", false);

// Disable weird Ctrl+Tab behavior
user_pref("browser.ctrlTab.recentlyUsedOrder", false);

// Disable password breach monitoring
user_pref("signon.management.page.breach-alerts.enabled", false);
