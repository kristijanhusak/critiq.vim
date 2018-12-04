
" Bitbucket functions.

let s:pass = $BB_PASS
let s:user = $BB_USER

let s:requests = {}
let s:handlers = {}

if !exists('g:critiq_bitbucket_url')
	let g:critiq_bitbucket_url = 'https://api.bitbucket.org/2.0'
endif

if !exists('g:critiq_bitbucket_oauth')
	let g:critiq_bitbucket_oauth = 0
endif

fu! s:get_repo_info()
	let remote_url = systemlist('git config --get remote.origin.url')[0]
	let url = split(remote_url, '/')

	if remote_url =~? '^http'
		return {
				\ 'username': url[-2],
				\ 'slug': substitute(url[-1], '.git$', '', '')
				\ }
	endif

	return {
			\ 'username': url[0].split(':')[-1],
			\ 'slug': substitute(url[-1], '.git$', '', '')
			\ }
endfu

fu! s:get_url(path)
	let repo = s:get_repo_info()
	echom string(repo)
	return printf('%s/repositories/%s/%s%s', g:critiq_bitbucket_url, repo.username, repo.slug, a:path)
endfu

" {{{ misc

fu! s:base_options(callback_name)
	let opts = {'callback': function(a:callback_name)}
	let headers = {'Accept': 'application/json'}

	if g:critiq_bitbucket_oauth
		let headers['Authorization'] = 'token ' . s:token
	else
		let opts.user = s:user . ':' . s:pass
	endif

	let opts.headers = headers
	return opts
endfu

" {{{ list_open_prs
fu! s:on_list_open_prs(response) abort
	echo a:response.stdout
	echo 'LENGTH'
	echo len(a:response.stdout)
"	let id = a:response['id']
"	let request = s:requests[id]
"	call remove(s:requests, id)
"
"	call s:check_gh_error(a:response)
"	let prs = a:response.body.items
"	call s:format_list(prs)
"	let total = a:response.body.total_count
"	call request['callback'](prs, total)
endfu

fu! s:list_open_prs(callback, page, ...)
	let opts = s:base_options('s:on_list_open_prs')
	let url = s:get_url('/pullrequests')
	echom 'URL '.url

	let id = critiq#request#send(url, opts)
	let s:requests[id] = { 'callback': a:callback }
endfu

let s:handlers['list_open_prs'] = function('s:list_open_prs')
" }}}

fu! critiq#providers#bitbucket#request(function_name, args)
	let Handler = s:handlers[a:function_name]
	return call(Handler, a:args)
endfu
" }}}
