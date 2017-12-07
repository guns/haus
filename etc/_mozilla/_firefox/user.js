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

// https://blog.mozilla.org/addons/2013/03/27/changes-to-console-log-behaviour-in-sdk-1-14/
user_pref("extensions.sdk.console.logLevel", "all");

/*
 * Public Preferences
 *
 * Search engine and privacy settings differ by profile.
 */

// Set blank homepage
user_pref("browser.startup.page", 0);
user_pref("browser.startup.homepage", "about:blank");
// Disable multiple tab open/close warnings
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.tabs.warnOnOpen", false);
// Disable lazy tab loading
user_pref("browser.sessionstore.restore_on_demand", false);

// Disable search suggestions
user_pref("browser.search.suggest.enabled", false);

// Set Dark Theme
user_pref("lightweightThemes.selectedThemeID", "firefox-compact-dark@mozilla.org");
user_pref("devtools.theme", "dark");
// Set UI density to compact
user_pref("browser.uidensity", 1);

// Font settings
user_pref("font.default.x-western", "sans-serif");
user_pref("font.name.monospace.x-western", "Consolas");
user_pref("font.name.sans-serif.x-western", "Segoe UI");
user_pref("font.name.serif.x-western", "Adobe Caslon Pro");
user_pref("font.size.fixed.x-western", 16);

// Disable safebrowsing filters
user_pref("browser.safebrowsing.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("pref.privacy.disable_button.change_blocklist", false);
// Disable password saving
user_pref("signon.rememberSignons", false);

// Disable spell check
user_pref("layout.spellcheckDefault", 0);
// Disable health data exfiltration
user_pref("datareporting.healthreport.uploadEnabled", false);
// Disable Telemetry
user_pref("toolkit.telemetry.enabled", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit", false);
// Disable Aurora updates
user_pref("app.update.auto", false);
user_pref("app.update.enabled", false);
// Disable searchplugin updates
user_pref("browser.search.update", false);
// Disable addon updates
user_pref("extensions.update.autoUpdateDefault", false);
// Disable OCSP
user_pref("security.OCSP.enabled", 0);

// Disable autofill
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.creditCards.enabled", false);

// Disable top sites
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);
user_pref("browser.newtabpage.activity-stream.migrationExpired", true);
user_pref("browser.newtabpage.activity-stream.prerender", false);
user_pref("browser.newtabpage.activity-stream.showSearch", false);
user_pref("browser.newtabpage.activity-stream.showTopSites", false);
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtabpage.enhanced", false);

/*
 * Hidden Preferences
 */

// Arrow key scroll distance
user_pref("toolkit.scrollbox.horizontalScrollDistance", 16);
user_pref("toolkit.scrollbox.verticalScrollDistance", 8);

// Allow unsigned extensions
user_pref("xpinstall.signatures.required", false);

// Keep window open when closing last tab
user_pref("browser.tabs.closeWindowWithLastTab", false);

// Disable warnings
user_pref("browser.tabs.warnOnCloseOtherTabs", false);
user_pref("browser.warnOnQuit", false);
user_pref("general.warnOnAboutConfig", false);
user_pref("network.warnOnAboutNetworking", false);

// Resist fingerprinting
user_pref("privacy.resistFingerprinting", true);

// Disable Geolocation
user_pref("geo.enabled", false);

// Disable more telemetry
user_pref("datareporting.policy.dataSubmissionEnabled", false);

// Disable session restore
user_pref("browser.sessionstore.interval", 2147483647);
user_pref("browser.sessionstore.max_resumed_crashes", 0);
user_pref("browser.sessionstore.max_serialize_back", 0);
user_pref("browser.sessionstore.max_serialize_forward", 0);
user_pref("browser.sessionstore.max_tabs_undo", 8);
user_pref("browser.sessionstore.max_windows_undo", 0);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.sessionstore.upgradeBackup.maxUpgradeBackups", 0);

// Disable Pocket
user_pref("browser.pocket.api", "");
user_pref("browser.pocket.enabledLocales", "");
user_pref("browser.pocket.oAuthConsumerKey", "");
user_pref("browser.pocket.site", "");
user_pref("browser.pocket.useLocaleList", false);
user_pref("extensions.pocket.api", "");
user_pref("extensions.pocket.enabled", false);
user_pref("extensions.pocket.oAuthConsumerKey", "");
user_pref("extensions.pocket.site", "");

// Disable Hello
user_pref("loop.enabled", false);
user_pref("loop.feedback.baseUrl", "");
user_pref("loop.gettingStarted.url", "");
user_pref("loop.learnMoreUrl", "");
user_pref("loop.legal.ToS_url", "");
user_pref("loop.legal.privacy_url", "");
user_pref("loop.oauth.google.scope", "");
user_pref("loop.ringtone", "");
user_pref("loop.server", "");
user_pref("loop.support_url", "");

// Disable WebRTC
user_pref("media.getusermedia.aec_enabled", false);
user_pref("media.getusermedia.agc_enabled", false);
user_pref("media.getusermedia.browser.enabled", false);
user_pref("media.getusermedia.noise_enabled", false);
user_pref("media.getusermedia.screensharing.allow_on_old_platforms", false);
user_pref("media.getusermedia.screensharing.allowed_domains", "");
user_pref("media.getusermedia.screensharing.enabled", false);
user_pref("media.gmp-gmpopenh264.enabled", false);
user_pref("media.gmp-gmpopenh264.lastUpdate", 1431513326);
user_pref("media.gmp-gmpopenh264.version", "1.4");
user_pref("media.gmp-manager.buildID", "20150702232110");
user_pref("media.gmp-manager.certs.1.commonName", "");
user_pref("media.gmp-manager.certs.1.issuerName", "");
user_pref("media.gmp-manager.certs.2.commonName", "");
user_pref("media.gmp-manager.certs.2.issuerName", "");
user_pref("media.gmp-manager.url", "");
user_pref("media.gmp-provider.enabled", false);
user_pref("media.peerconnection.default_iceservers", "");
user_pref("media.peerconnection.enabled", false);
user_pref("media.peerconnection.ice.loopback", false);
user_pref("media.peerconnection.identity.enabled", false);
user_pref("media.peerconnection.turn.disable", true);
user_pref("media.peerconnection.use_document_iceservers", false);
user_pref("media.peerconnection.video.enabled", false);
user_pref("media.peerconnection.video.h264_enabled", false);

// Remove all external URLs
user_pref("accessibility.support.url", "");
user_pref("app.feedback.baseURL", "");
user_pref("app.productInfo.baseURL", "");
user_pref("app.releaseNotesURL", "");
user_pref("app.support.baseURL", "");
user_pref("app.support.e10sAccessibilityUrl", "");
user_pref("app.update.url", "");
user_pref("app.update.url.details", "");
user_pref("app.update.url.manual", "");
user_pref("breakpad.reportURL", "");
user_pref("browser.aboutHomeSnippets.updateUrl", "");
user_pref("browser.contentHandlers.types.0.uri", "");
user_pref("browser.customizemode.tip0.learnMoreUrl", "");
user_pref("browser.customizemode.tip0.shown", true);
user_pref("browser.dictionaries.download.url", "");
user_pref("browser.geolocation.warning.infoURL", "");
user_pref("browser.newtabpage.activity-stream.default.sites", "");
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories.options", "{}");
user_pref("browser.newtabpage.activity-stream.telemetry.ping.endpoint", "");
user_pref("browser.newtabpage.activity-stream.tippyTop.service.endpoint", "");
user_pref("browser.newtabpage.directory.ping", "");
user_pref("browser.newtabpage.directory.source", "");
user_pref("browser.ping-centre.production.endpoint", "");
user_pref("browser.ping-centre.staging.endpoint", "");
user_pref("browser.safebrowsing.downloads.remote.url", "");
user_pref("browser.safebrowsing.provider.google.advisoryURL", "");
user_pref("browser.safebrowsing.provider.google.gethashURL", "");
user_pref("browser.safebrowsing.provider.google.reportMalwareMistakeURL", "");
user_pref("browser.safebrowsing.provider.google.reportPhishMistakeURL", "");
user_pref("browser.safebrowsing.provider.google.reportURL", "");
user_pref("browser.safebrowsing.provider.google.updateURL", "");
user_pref("browser.safebrowsing.provider.google4.advisoryURL", "");
user_pref("browser.safebrowsing.provider.google4.dataSharingURL", "");
user_pref("browser.safebrowsing.provider.google4.gethashURL", "");
user_pref("browser.safebrowsing.provider.google4.reportMalwareMistakeURL", "");
user_pref("browser.safebrowsing.provider.google4.reportPhishMistakeURL", "");
user_pref("browser.safebrowsing.provider.google4.reportURL", "");
user_pref("browser.safebrowsing.provider.google4.updateURL", "");
user_pref("browser.safebrowsing.provider.mozilla.gethashURL", "");
user_pref("browser.safebrowsing.provider.mozilla.updateURL", "");
user_pref("browser.safebrowsing.reportMalwareMistakeURL", "");
user_pref("browser.safebrowsing.reportPhishMistakeURL", "");
user_pref("browser.safebrowsing.reportPhishURL", "");
user_pref("browser.search.geoSpecificDefaults.url", "");
user_pref("browser.search.geoip.url", "");
user_pref("browser.search.searchEnginesURL", "");
user_pref("browser.selfsupport.url", "");
user_pref("browser.uitour.themeOrigin", "");
user_pref("browser.uitour.url", "");
user_pref("browser.usedOnWindows10.introURL", "");
user_pref("captivedetect.canonicalURL", "");
user_pref("datareporting.healthreport.about.reportUrl", "");
user_pref("datareporting.healthreport.infoURL", "");
user_pref("datareporting.policy.firstRunURL", "");
user_pref("devtools.devedition.promo.url", "");
user_pref("devtools.devices.url", "");
user_pref("devtools.gcli.imgurUploadURL", "");
user_pref("devtools.gcli.jquerySrc", "");
user_pref("devtools.gcli.lodashSrc", "");
user_pref("devtools.gcli.underscoreSrc", "");
user_pref("devtools.webide.adaptersAddonURL", "");
user_pref("devtools.webide.adbAddonURL", "");
user_pref("devtools.webide.addonsURL", "");
user_pref("devtools.webide.monitorWebSocketURL", "");
user_pref("devtools.webide.simulatorAddonsURL", "");
user_pref("devtools.webide.templatesURL", "");
user_pref("dom.mozApps.signed_apps_installable_from", "");
user_pref("dom.push.serverURL", "");
user_pref("experiments.manifest.uri", "");
user_pref("extensions.blocklist.detailsURL", "");
user_pref("extensions.blocklist.itemURL", "");
user_pref("extensions.blocklist.url", "");
user_pref("extensions.geckoProfiler.symbols.url", "");
user_pref("extensions.getAddons.get.url", "");
user_pref("extensions.getAddons.getWithPerformance.url", "");
user_pref("extensions.getAddons.link.url", "");
user_pref("extensions.getAddons.recommended.url", "");
user_pref("extensions.getAddons.search.browseURL", "");
user_pref("extensions.getAddons.search.url", "");
user_pref("extensions.getAddons.themes.browseURL", "");
user_pref("extensions.shield-recipe-client.api_url", "");
user_pref("extensions.shield-recipe-client.shieldLearnMoreUrl", "");
user_pref("extensions.systemAddon.update.url", "");
user_pref("extensions.update.background.url", "");
user_pref("extensions.update.url", "");
user_pref("extensions.webcompat-reporter.newIssueEndpoint", "");
user_pref("extensions.webservice.discoverURL", "");
user_pref("gecko.handlerService.schemes.irc.0.uriTemplate", "");
user_pref("gecko.handlerService.schemes.ircs.0.uriTemplate", "");
user_pref("gecko.handlerService.schemes.mailto.0.uriTemplate", "");
user_pref("gecko.handlerService.schemes.mailto.1.uriTemplate", "");
user_pref("gecko.handlerService.schemes.webcal.0.uriTemplate", "");
user_pref("geo.wifi.uri", "");
user_pref("identity.fxaccounts.auth.uri", "");
user_pref("identity.fxaccounts.remote.connectdevice.uri", "");
user_pref("identity.fxaccounts.remote.email.uri", "");
user_pref("identity.fxaccounts.remote.force_auth.uri", "");
user_pref("identity.fxaccounts.remote.oauth.uri", "");
user_pref("identity.fxaccounts.remote.profile.uri", "");
user_pref("identity.fxaccounts.remote.signin.uri", "");
user_pref("identity.fxaccounts.remote.signup.uri", "");
user_pref("identity.fxaccounts.remote.webchannel.uri", "");
user_pref("identity.fxaccounts.settings.devices.uri", "");
user_pref("identity.fxaccounts.settings.uri", "");
user_pref("identity.mobilepromo.android", "");
user_pref("identity.mobilepromo.ios", "");
user_pref("identity.sync.tokenserver.uri", "");
user_pref("lightweightThemes.getMoreURL", "");
user_pref("lightweightThemes.recommendedThemes", "[]");
user_pref("media.decoder-doctor.new-issue-endpoint", "");
user_pref("privacy.trackingprotection.introURL", "");
user_pref("security.ssl.errorReporting.url", "");
user_pref("services.settings.server", "");
user_pref("services.sync.fxa.privacyURL", "");
user_pref("services.sync.fxa.termsURL", "");
user_pref("services.sync.jpake.serverURL", "");
user_pref("services.sync.privacyURL", "");
user_pref("services.sync.serverURL", "");
user_pref("services.sync.statusURL", "");
user_pref("services.sync.syncKeyHelpURL", "");
user_pref("services.sync.termsURL", "");
user_pref("social.directories", "");
user_pref("social.shareDirectory", "");
user_pref("social.whitelist", "");
user_pref("startup.homepage_override_url", "");
user_pref("startup.homepage_welcome_url", "");
user_pref("toolkit.crashreporter.infoURL", "");
user_pref("toolkit.datacollection.infoURL", "");
user_pref("toolkit.telemetry.infoURL", "");
user_pref("toolkit.telemetry.server", "");
user_pref("webchannel.allowObject.urlWhitelist", "");
user_pref("webextensions.storage.sync.serverURL", "");
user_pref("xpinstall.signatures.devInfoURL", "");
