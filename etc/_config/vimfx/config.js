//  __      ___           ______
//  \ \    / (_)         |  ____|
//   \ \  / / _ _ __ ___ | |____  __
//    \ \/ / | | '_ ` _ \|  __\ \/ /
//     \  /  | | | | | | | |   >  <
//      \/   |_|_| |_| |_|_|  /_/\_\
//
//           guns <self@sungpae.com>

//
// Options
//

vimfx.set('prevent_autofocus', true);

//
// Commands
//

let {commands} = vimfx.modes.normal;

function addLocationCommand(name, url) {
	vimfx.addCommand({ name: name, description: `Open ${url}`}, ({vim}) => {
		vim.window.gBrowser.loadOneTab(url, {inBackground: false});
	})
}

vimfx.addCommand({
	name: 'tst_toggle_window',
	description: 'Toggle TreeStyleTabs window',
}, ({vim}) => {
	vim.window.TreeStyleTabService.autoHideWindow.toggleMode();
});

vimfx.addCommand({
	name: 'tst_close_child_tabs',
	description: 'Close child tabs of current tab',
}, ({vim}) => {
	vim.window.gBrowser.treeStyleTab._closeChildTabs(vim.window.gBrowser.mCurrentTab);
});

vimfx.addCommand({
	name: 'tst_select_sibling_next',
	description: 'Select next TST sibling tab',
}, ({vim}) => {
	let b = vim.window.gBrowser;
	let t = b.treeStyleTab.getNextSiblingTab(b.mCurrentTab);
	if (t) {
		t.click();
	} else {
		let ts = b.treeStyleTab.getSiblingTabs(b.mCurrentTab);
		if (ts[0]) ts[0].click();
	}
});

vimfx.addCommand({
	name: 'tst_select_sibling_prev',
	description: 'Select previous TST sibling tab',
}, ({vim}) => {
	let b = vim.window.gBrowser;
	var t = b.treeStyleTab.getPreviousSiblingTab(b.mCurrentTab);
	if (t) {
		t.click();
	} else {
		let ts = b.treeStyleTab.getSiblingTabs(b.mCurrentTab);
		if (ts[ts.length-1]) ts[ts.length-1].click();
	}
});

addLocationCommand('open_addons', 'about:addons');
addLocationCommand('open_config', 'about:config');
addLocationCommand('open_preferences', 'about:preferences');
addLocationCommand('open_umatrix_background', 'chrome://umatrix/content/popup.html');
addLocationCommand('open_umatrix_rules', 'chrome://umatrix/content/dashboard.html#user-rules');
addLocationCommand('open_umatrix_logger', 'chrome://umatrix/content/logger-ui.html');

//
// Bindings
//

const BINDINGS = [
	['copy_current_url',        'yy Y'],
	['find',                    '\\ /'],
	['follow',                  "'"],
	['follow_in_tab',           ';'],
	['history_back',            '<C-h> H'],
	['history_forward',         '<C-l> L'],
	['open_addons',             '<C-A>', true],
	['open_config',             '<C-C>', true],
	['open_preferences',        '<C-P>', true],
	['open_umatrix_background', '<C-B>', true],
	['open_umatrix_rules',      '<C-M>', true],
	['open_umatrix_logger',     '<C-L>', true],
	['reload_config_file',      '<C-x>r'],
	['scroll_half_page_down',   'f'],
	['scroll_half_page_up',     'b'],
	['scroll_page_down',        '<C-f> <Space>'],
	['scroll_page_up',          '<C-b> <S-Space>'],
	['scroll_to_mark',          '`'],
	['stop',                    'x'],
	['stop_all',                'ax'],
	['tab_close',               'd'],
	['tab_close_other',         '<C-O>'],
	['tab_move_backward',       '<A-->'],
	['tab_move_forward',        '<A-=>'],
	['tab_restore',             'u'],
	['tab_restore_list',        'U'],
	['tab_select_next',         '<C-j> <Tab>   J gt'],
	['tab_select_previous',     '<C-k> <S-Tab> K gT'],
	['tst_close_child_tabs',    'D', true],
	['tst_select_sibling_next', '<C-n>', true],
	['tst_select_sibling_prev', '<C-p>', true],
	['tst_toggle_window',       'w', true],
	['window_new',              'W'],
	['window_new_private',      '<A-w>'],
];

for (let [command, keys, custom] of BINDINGS) {
	vimfx.set(`${custom ? 'custom.' : ''}mode.normal.${command}`, keys);
}
