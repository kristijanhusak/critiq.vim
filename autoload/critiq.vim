
fu! critiq#comment()
	throw "Not implemented"
endfu

fu! critiq#checkout()
	let pr = b:critiq_pull_request
	let sha = pr['head']['sha']
	let branch = pr['head']['ref']
	call system('git fetch origin ' . shellescape('pull/' . pr['number'] . '/head:' . branch))
	call system('git checkout ' . shellescape(branch))
	echo 'Checked out to branch: ' . branch
endfu

fu! critiq#send_review(event)
	let body = join(getline(1, '$'), '\n')
	call critiq#github#submit_review(b:critiq_pull_request, a:event, body)
	bd
endfu

fu! critiq#review(state)
	let pr = b:critiq_pull_request
	belowright new
	let b:critiq_pull_request = pr
	let b:critiq_state = a:state
	setl buftype=nofile
	setl noswapfile
	startinsert
	nnoremap <buffer> q :bd<cr>
	nnoremap <buffer> s :call critiq#send_review(b:critiq_state)<cr>
endfu

fu! s:hollow_tab(lines)
	tabnew
	setl buftype=nofile
	setl noswapfile
	call setline(1, a:lines)
	setl nomodifiable
endfu

fu! s:on_open_pr_diff(response)
	let text = a:response['body']
	let pr = b:critiq_pull_requests[line('.') - 1]
	call s:hollow_tab(text)
	let b:critiq_pull_request = pr
	setf diff
	nnoremap <buffer> q :tabc<cr>
	nnoremap <buffer> ra :call critiq#review('APPROVE')<cr>
	nnoremap <buffer> rr :call critiq#review('REQUEST_CHANGES')<cr>
	nnoremap <buffer> rc :call critiq#review('COMMENT')<cr>
	nnoremap <buffer> c :call critiq#comment()<cr>
	nnoremap <buffer> <leader>c :call critiq#checkout()<cr>
endfu

fu! critiq#open_pr()
	let pr = b:critiq_pull_requests[line('.') - 1]
	call critiq#github#diff(pr, function('s:on_open_pr_diff'))
endfu

fu! critiq#on_pull_requests(response)
	let b:critiq_pull_requests = a:response['body']
	let lines = []
	for pr in a:response['body']
		let state = empty(pr['reviews']) ? 'NONE' : pr['reviews'][0]['state']
		call add(lines, '#' . pr['number'] . ' (' . state . '): ' . pr['title'])
	endfor

	call s:hollow_tab(lines)
	let b:critiq_pull_requests = a:response['body']
	setf critiq_pr_list
endfu

fu! critiq#list_pull_requests()
	call critiq#github#list_open_prs(function('critiq#on_pull_requests'))
endfu

