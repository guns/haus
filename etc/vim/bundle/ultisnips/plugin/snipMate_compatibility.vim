if exists('did_UltiSnips_snipmate_compatibility')
	finish
elseif !(has('python') || has('python3'))
    let did_UltiSnips_snipmate_compatibility = 1
    finish
endif
let did_UltiSnips_snipmate_compatibility = 1

if ! exists('g:snips_author')
	let g:snips_author = "John Doe"
endif
