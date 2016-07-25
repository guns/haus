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

// Font settings
user_pref("font.default.x-western", "sans-serif");
user_pref("font.name.monospace.x-western", "Consolas");
user_pref("font.name.sans-serif.x-western", "Segoe UI");
user_pref("font.name.serif.x-western", "Adobe Caslon Pro");
user_pref("font.size.fixed.x-western", 16);

// Disable safebrowsing filters
user_pref("browser.safebrowsing.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
// Disable password saving
user_pref("signon.rememberSignons", false);

// Disable spell check
user_pref("layout.spellcheckDefault", 0);
// Disable health data exfiltration
user_pref("datareporting.healthreport.uploadEnabled", false);
// Disable searchplugin updates
user_pref("browser.search.update", false);
// Disable OCSP
user_pref("security.OCSP.enabled", 0);

/*
 * Hidden Preferences
 */

// Disable about:config warning
user_pref("general.warnOnAboutConfig", false);

// Disable closing other tabs warning
user_pref("browser.tabs.warnOnCloseOtherTabs", false);

// Disable Geolocation
user_pref("geo.enabled", false);

// Disable Pocket
user_pref("browser.pocket.api", "");
user_pref("browser.pocket.enabled", false);
user_pref("browser.pocket.enabledLocales", "");
user_pref("browser.pocket.oAuthConsumerKey", "");
user_pref("browser.pocket.site", "");
user_pref("browser.pocket.useLocaleList", false);

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

// Scrub external URLs
user_pref("app.feedback.baseURL", "");
user_pref("app.support.baseURL", "");
user_pref("app.update.url", "");
user_pref("app.update.url.details", "");
user_pref("app.update.url.manual", "");
user_pref("breakpad.reportURL", "");
user_pref("browser.aboutHomeSnippets.updateUrl", "");
user_pref("browser.apps.URL", "");
user_pref("browser.contentHandlers.types.0.uri", "");
user_pref("browser.customizemode.tip0.learnMoreUrl", "");
user_pref("browser.dictionaries.download.url", "");
user_pref("browser.geolocation.warning.infoURL", "");
user_pref("browser.newtabpage.directory.ping", "");
user_pref("browser.newtabpage.directory.source", "");
user_pref("browser.safebrowsing.appRepURL", "");
user_pref("browser.safebrowsing.gethashURL", "");
user_pref("browser.safebrowsing.malware.reportURL", "");
user_pref("browser.safebrowsing.reportErrorURL", "");
user_pref("browser.safebrowsing.reportGenericURL", "");
user_pref("browser.safebrowsing.reportMalwareErrorURL", "");
user_pref("browser.safebrowsing.reportMalwareURL", "");
user_pref("browser.safebrowsing.reportPhishURL", "");
user_pref("browser.safebrowsing.reportURL", "");
user_pref("browser.safebrowsing.updateURL", "");
user_pref("browser.search.geoip.url", "");
user_pref("browser.search.searchEnginesURL", "");
user_pref("browser.selfsupport.url", "");
user_pref("browser.trackingprotection.gethashURL", "");
user_pref("browser.trackingprotection.updateURL", "");
user_pref("browser.uitour.themeOrigin", "");
user_pref("browser.uitour.url", "");
user_pref("datareporting.healthreport.about.reportUrl", "");
user_pref("datareporting.healthreport.documentServerURI", "");
user_pref("datareporting.healthreport.infoURL", "");
user_pref("devtools.devedition.promo.url", "");
user_pref("devtools.devices.url", "");
user_pref("devtools.gcli.jquerySrc", "");
user_pref("devtools.gcli.lodashSrc", "");
user_pref("devtools.gcli.underscoreSrc", "");
user_pref("devtools.webide.adaptersAddonURL", "");
user_pref("devtools.webide.adbAddonURL", "");
user_pref("devtools.webide.addonsURL", "");
user_pref("devtools.webide.simulatorAddonsURL", "");
user_pref("devtools.webide.templatesURL", "");
user_pref("dom.mozApps.signed_apps_installable_from", "");
user_pref("experiments.manifest.uri", "");
user_pref("extensions.blocklist.detailsURL", "");
user_pref("extensions.blocklist.itemURL", "");
user_pref("extensions.blocklist.url", "");
user_pref("extensions.getAddons.get.url", "");
user_pref("extensions.getAddons.getWithPerformance.url", "");
user_pref("extensions.getAddons.recommended.url", "");
user_pref("extensions.getAddons.search.browseURL", "");
user_pref("extensions.getAddons.search.url", "");
user_pref("extensions.update.background.url", "");
user_pref("extensions.update.url", "");
user_pref("extensions.webservice.discoverURL", "");
user_pref("gecko.handlerService.schemes.irc.0.uriTemplate", "");
user_pref("gecko.handlerService.schemes.ircs.0.uriTemplate", "");
user_pref("gecko.handlerService.schemes.mailto.0.uriTemplate", "");
user_pref("gecko.handlerService.schemes.mailto.1.uriTemplate", "");
user_pref("gecko.handlerService.schemes.webcal.0.uriTemplate", "");
user_pref("geo.wifi.uri", "");
user_pref("identity.fxaccounts.auth.uri", "");
user_pref("identity.fxaccounts.remote.force_auth.uri", "");
user_pref("identity.fxaccounts.remote.oauth.uri", "");
user_pref("identity.fxaccounts.remote.profile.uri", "");
user_pref("identity.fxaccounts.remote.signin.uri", "");
user_pref("identity.fxaccounts.remote.signup.uri", "");
user_pref("identity.fxaccounts.settings.uri", "");
user_pref("lightweightThemes.getMoreURL", "");
user_pref("pfs.datasource.url", "");
user_pref("plugins.update.url", "");
user_pref("readinglist.server", "");
user_pref("security.ssl.errorReporting.url", "");
user_pref("services.push.serverURL", "");
user_pref("services.sync.fxa.privacyURL", "");
user_pref("services.sync.fxa.termsURL", "");
user_pref("services.sync.jpake.serverURL", "");
user_pref("services.sync.privacyURL", "");
user_pref("services.sync.serverURL", "");
user_pref("services.sync.statusURL", "");
user_pref("services.sync.syncKeyHelpURL", "");
user_pref("services.sync.termsURL", "");
user_pref("services.sync.tokenServerURI", "");
user_pref("social.directories", "");
user_pref("social.shareDirectory", "");
user_pref("social.whitelist", "");
user_pref("startup.homepage_welcome_url", "");
user_pref("toolkit.crashreporter.infoURL", "");
user_pref("toolkit.telemetry.infoURL", "");
user_pref("toolkit.telemetry.server", "");
