" Author:  Wind 
" Date:  2004-11-26  
" Email:  wind-xp@tut.by 
" Version:  0.5 
"

"requirments: multvals.vim
"



let TGM_TAG_FILE_REPLACEMENT="${TAG_FILE}"
" sedCmd can contain:
" ${TAG_FILE} - will be replaced with actual tagfile

" global functions
function! TagRequest(grepCmd,sedCmd,...) "{{{1
	"fnamemodify("./TAGS",':P')
	if a:0==0 "{{{2
		return TagRequest(a:grepCmd,a:sedCmd,&tags)
	endif "}}}2
	call Logging_Start ("TagRequest",a:grepCmd)
	let iter="TGM_ITER"
	let i=0
	let tagFiles=''
	while i<a:0 "{{{2
		let i=i+1
		let tagFiles=tagFiles.','.a:{i}
	endwhile "}}}2
   call MvIterCreate(tagFiles,',', iter)
	let result=''
	let tmp=tempname()
	while MvIterHasNext(iter) "{{{2
		let tagFile=MvIterNext(iter)
		call s:TagRequest(a:grepCmd,a:sedCmd,tmp,tagFile)
	endwhile "}}}2
	call MvIterDestroy(iter)
	"echo result
	let result=system("uniq ".tmp)
	call delete(tmp)
	call Logging_End("TagRequest")
	"echo result
	return result
endfunction "}}}1

function! TGM_RefreshTagFile(file,path) "{{{1
	let oldDir=getcwd()
	exec 'lcd '.a:path
	let file=fnamemodify(a:file,':~:.')
	"let flags='--tag-relative=no --sort=yes --excmd=pattern --fields=+a+f+i+k+m+s '
	"	       a   Access (or export) of class members
	"	       f   File-restricted scoping [enabled]
	"	       i   Inheritance information
	"	       k   Kind of tag as a single letter [enabled]
	"	       K   Kind of tag as full name
	"	       l   Language of source file containing tag
	"	       m   Implementation information
	"	       n   Line number of tag definintion
	"	       s   Scope of tag definition [enabled]
	"	       z   Include the "kind:" key in kind field
	let flags='--tag-relative=yes --sort=yes --excmd=pattern --fields=+a+f+i+m+k+s '
	let command='exctags '.flags.' -f '.a:file.' -R '
	echo system(command)
	exec 'lcd '.oldDir
endfunction "}}}1

function! TGM_ConstructSedCMD(request) "{{{1
	let sedcmd="s/([^[:blank:]]+)\t([^[:blank:]]+)\t\\/(.*)\\/;\"".
				\"\t(.*)$/"
	let request=substitute(a:request,'${TAG}','\\1','g')
	let request=substitute(request,'${FILE}','\\2','g')
	let request=substitute(request,'${EXCMD}','\\3','g')
	let request=substitute(request,'${KIND}','\\4','g')
	let sedcmd=sedcmd.request.'/gp'
	return sedcmd
endfunction "}}}1


"script private functions
function! s:TagRequest(grepCmd,sedCmd,tmpFile,tagFile) "{{{1
	call Logging_Start ("s:TagRequest","grepcmd=".a:grepCmd,"tagFile=".a:tagFile)
	let tagFile=a:tagFile
	let eTagFile=substitute(tagFile,'/','\\\\/','g')
	let sedCmd=substitute(a:sedCmd,g:TGM_TAG_FILE_REPLACEMENT,eTagFile,'g')
	" TODO: try grep --mmap
	let command="egrep --mmap -h -s '".a:grepCmd."' ".tagFile."|sed -E -n -e '".sedCmd."'>".&shellredir.a:tmpFile
	"."' |uniq".
	let result=system(command)
	call Logging_End ("s:TagRequest")
	return result
endfunction "}}}1

