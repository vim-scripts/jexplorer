"
" Author:  Yury Altukhou 
" Date:    2004/12/22
" Email:   
" Version: 0.5


" setup command
runtime tree.vim

command! -nargs=* -complete=dir JExplorer cal JExplorer ()
"command! -nargs=* -complete=dir JExplorer cal JExplorer ()
noremap <silent> <F11> :call ToggleShowExplorer ()<CR>


let s:IDENTIFIER="[_[:alnum:]]+"

"attributes format <tag kind:name=value:name=value:...>

fu! JExplorer () "{{{1
	call Tree_NewTreeWindow ("<p>",1,0,20,15,"JExplorer_InitOptions")
endf "}}}1

fu! ToggleShowExplorer() "{{{1
	if exists ("g:jexplorer_loaded")
		exe s:window_bufnr."bd"
		unlet g:jexplorer_loaded
	else
		call JExplorer ()
	end
endf "}}}1

function! JExplorer_InitOptions() "{{{1
"	call Logging_Debug("JExplorer_InitOptions",50)
	setfiletype jexplorer
	let b:Tree_GetSubNodesFunction="JExplorer_GetSubNodes"
	let b:Tree_IsLeafFunction="JExplorer_IsLeaf"
	let b:Tree_pathSeparator='.'
	let b:Tree_ColorFunction="JExplorer_InitColors"
	let b:Tree_InitMappingsFunction="JExplorer_InitMappings"
endfunction "}}}1

function! JExplorer_InitMappings() "{{{1
"	call Logging_Debug("JExplorer_InitMappings",50)
	nmap <buffer> O :call <SID>FindTagUnderCursor()<CR>
	noremap <silent> <buffer> i :call <SID>ImportTags()<CR>
	nmap <buffer> <space> :call <SID>ShowPrototypeUnderCursor()<CR>
endfunction "}}}1

function! JExplorer_GetSubNodes (path) "{{{1
	let path= s:GetPath(a:path) 
	let path= substitute (path,'^.','','')
	let attributes=s:GetAttributes(a:path)
	if s:IsPackage(attributes) "{{{2
		return JGetSubPackages (path,attributes)."\n".JGetClasses (path,attributes)
	elseif s:IsClass(attributes) 
		"return JGetInnerClasses(path,attributes)."\n".JGetClassMethods (path,attributes)."\n".JGetClassFields (path,attributes)
		return JGetClassMembers(path,attributes)
	elseif s:IsInterface(attributes) 
		return JGetClassMembers(path,attributes)
		"JGetClassMethods (path,attributes)."\n".JGetClassFields (path,attributes)
	endif "}}}2
endfunction "}}}1

function! JExplorer_IsLeaf (path) "{{{1
	let attributes=<SID>GetAttributes(a:path)
	return !(<SID>IsPackage(attributes) || <SID>IsClass(attributes) || <SID>IsInterface(attributes))
endfunction "}}}1

function! JExplorer_InitColors()  "{{{1
"	call Logging_Debug("JExplorer_InitColors",50)
endfunction "}}}1


function! JGetSubPackages (path,attributes) "{{{1
"	call Logging_Start("JGetSubPackages",a:path)
	let path=substitute (a:path,'\.','\\.','g')
	if path!="" "{{{
		let path=path."\\."
	endif "}}}2
	let grepPatt="^".path.".*\tp$"
	let sedCommand="s/^".path."(".s:IDENTIFIER.")(\\.".s:IDENTIFIER.")*\t.*$/\\1<p>/gp"
	let result=TagRequest(grepPatt,sedCommand)
"	"call Logging_End ("JGetSubPackages")
"	return Logging_End ("JGetSubPackages",result)
	return result
endfunction "}}}1

function! JGetFilesInThePackage (path,attributes) "{{{1
"	call Logging_Start("JGetFilesInThePackage")
	let path=substitute (a:path,'\.','\\.','g')
	let grepPatt='^'.path."\t"
	let sedCommand="s/".grepPatt."([^[:blank:]]*)\t.*$/\\1/gp"
	let result=TagRequest(grepPatt,sedCommand)
"	call Logging_End("JGetFilesInThePackage")
	return result
endfunction "}}}1

function! JGetClasses (path,attributes) "{{{1
"	call Logging_Start("JGetClasses","path=".a:path)
	let path=a:path
	let jfiles =JGetFilesInThePackage (path,a:attributes)
	let jfiles =substitute (jfiles,'\n','|','g')
	let jfiles =substitute (jfiles,'|$','','')
	let grepPatt="^".s:IDENTIFIER."\t(".jfiles.")\t.*\"\t(c|i)\t?.*$"  
	let sedCommand=TGM_ConstructSedCMD(
				\"${TAG}<${KIND}@file=${FILE}@excmd=${EXCMD}@tagfile=${TAG_FILE}>")
	let result=TagRequest(grepPatt,sedCommand)
"	return Logging_End ("JGetClasses",result)
	return result
endfunction "}}}1

function! JGetClassMethods (path,attributes ) "{{{1
"	call Logging_Start("JGetClassMethods")
	let path=a:path
	let outterclass=s:GetOutterClassAttribute(a:attributes) 
	let tagFile=s:GetTagFileAttribute(a:attributes) 
	let className=substitute (path,'^\(\w\+\.\)*','','')
	if outterclass!='' "{{{2
		let className=outterclass.'.'.className
	endif "}}}2
	let javaFile =s:GetFileAttribute ( a:attributes)
	"echo javaFile
	let grepPatt="^".s:IDENTIFIER."\t".javaFile."\t.*\"\tm\t(class|interface):".className."(\t.*)?$"
	let sedCommand=TGM_ConstructSedCMD(
				\"${TAG}<${KIND}@file=${FILE}@excmd=${EXCMD}@tagfile=${TAG_FILE}>")
	let result=TagRequest(grepPatt,sedCommand,tagFile)
"	return Logging_End ("JGetClassMethods",result)
	return result
endfunction "}}}1

function! JGetClassFields (path,attributes ) "{{{1
"	call Logging_Start("JGetClassFields")
	let path=a:path
	let outterclass=s:GetOutterClassAttribute(a:attributes) 
	let className=substitute (path,'^\(\w\+\.\)*','','')
	let tagFile=s:GetTagFileAttribute(a:attributes) 
	if outterclass!='' "{{{2
		let className=outterclass.'.'.className
	endif "}}}2
	let javaFile =s:GetFileAttribute ( a:attributes)
	let grepPatt="^".s:IDENTIFIER."\t".javaFile."\t.*\"\tf\t(class|interface):".className."(\t.*)?$"  
	let sedCommand=TGM_ConstructSedCMD(
				\"${TAG}<${KIND}@file=${FILE}@excmd=${EXCMD}@tagfile=${TAG_FILE}>")
	let result=TagRequest(grepPatt,sedCommand,tagFile)
"	return Logging_End ("JGetClassFields",result)
	return result
endfunction "}}}1

function! JGetInnerClasses (path,attributes ) "{{{1
"	call Logging_Start("JGetInnerClasses")
	let path=a:path
	let class=substitute(path,".*\\.\\([^.]\\+\\)$","\\1",'')
	let tagFile=s:GetTagFileAttribute(a:attributes) 
	echo class
	let jfile =s:GetFileAttribute(a:attributes)
	let grepPatt="^".s:IDENTIFIER."\t".jfile."\t.*\"\t(c|i)\tclass:".class."$"  
	"let sedCommand="s/^(".s:IDENTIFIER.")\t([^[:blank:]]+)\t(.*)\"\t(.).*$/\\1<\\4:file=\\2:excmd=\\3:outterclass=".class.":tagfile=".g:TGM_TAG_FILE_REPLACEMENT.">/gp"
	let sedCommand=TGM_ConstructSedCMD(
				\"${TAG}<${KIND}@file=${FILE}@excmd=${EXCMD}@tagfile=${TAG_FILE}>")
	let result=TagRequest(grepPatt,sedCommand,tagFile)
"	return Logging_End ("JGetInnerClasses",result)
	return result
endfunction "}}}1

function! JGetClassMembers (path,attributes ) "{{{1
"	call Logging_Start("JGetClassMembers","class=".a:path)
	let path=a:path
	let outterclass=s:GetOutterClassAttribute(a:attributes) 
	let className=substitute (path,'^\(\w\+\.\)*','','')
	let tagFile=s:GetTagFileAttribute(a:attributes) 
	if outterclass!='' "{{{2
		let className=outterclass.'.'.className
	endif "}}}2
	let javaFile =s:GetFileAttribute ( a:attributes)
	let grepPatt="^".s:IDENTIFIER."\t".javaFile."\t.*\"\t[fmci]\t(class|interface):".className."(\t.*)?$"  
	let sedCommand=TGM_ConstructSedCMD(
				\"${TAG}<${KIND}@file=${FILE}@excmd=${EXCMD}@tagfile=${TAG_FILE}>")
	let result=TagRequest(grepPatt,sedCommand,tagFile)
"	return Logging_End ("JGetClassMembers",result)
	return result
endfunction "}}}1

let s:filename =expand("<sfile>:p")
function! UninstallJExplorer() "{{{1
	call Uninstall (s:filename)
endfunction "}}}1

" script private functions

function! s:ImportTag() "{{{1
	let path=Tree_GetPathUnderCursor()
	let attributes=s:GetAttributes(path)
	let tag=s:GetPath(path)
	let tag=substitute(tag,'^\.*','','')
	let import=''
	if s:IsPackage(attributes) "{{{2
		let import="import ".tag.'.*;'
	elseif s:IsClass(attributes) || s:IsInterface(attributes)
		let import="import ".tag.';'
	elseif s:IsMethod(attributes) 
		let prototype=s:GetPrototypeUnderCursor()
		let import=prototype."{\n}\n"
	endif "}}}2
	if import!='' "{{{2
		wincmd p
		execute "normal o".import
		wincmd p
	endif "}}}2
endfunction "}}}1

function! s:ImportTags() range "{{{1
	let i=a:firstline
	while i<=a:lastline "{{{2
		exec "normal ".i."G"
		call s:ImportTag()
		let i=i+1
	endwhile "}}}2
	wincmd p
endfunction "}}}1

function! s:ShowPrototypeUnderCursor () "{{{1
	let prototype=s:GetPrototypeUnderCursor()
	echohl Question
	echo prototype
	echohl None
endfunction "}}}1

function! s:GetPrototypeUnderCursor () "{{{1
	let path=Tree_GetPathUnderCursor()
	let attributes=s:GetAttributes(path)
	let prototype=s:GetExCommand(attributes)
	let prototype=substitute(prototype,'^^\s*','','')
	let prototype=substitute(prototype,';\?{\?\s*\$$','','')
	return prototype
endfunction "}}}1

function! s:FindTagUnderCursor() "{{{1
	let path=Tree_GetPathUnderCursor()
	let attributes=s:GetAttributes(path)
	let aFile=s:GetJavaFile(attributes)
	let aFile=fnamemodify(aFile,':p')
	if filereadable(aFile) "{{{2
		" go to last accessed buffer
		let excmd=s:GetExCommand(attributes)
		let excmd=strpart(excmd,1,strlen(excmd)-3)
		wincmd p
		" append sequence for opening file
		execute "lcd ".fnamemodify(aFile,":h")
		execute "e ".aFile
		silent call search(excmd,'w')
		setlocal modifiable
	endif "}}}2
endfunction "}}}1

function! s:IsPackage (attributes) "{{{1
	return a:attributes[0]=='p'
endfunction "}}}1

function! s:IsClass (attributes) "{{{1
	return a:attributes[0]=='c'
endfunction "}}}1

function! s:IsMethod (attributes) "{{{1
	return a:attributes[0]=='m'
endfunction "}}}1

function! s:IsInterface (attributes) "{{{1
	return a:attributes[0]=='i'
endfunction "}}}1

function! s:GetJavaFile ( attributes ) "{{{1
	"return substitute (a:attributes,'\(c\|i\):\(.*\)','\2','')
	let aFile =s:GetFileAttribute(a:attributes)
	let aTagFile =s:GetTagFileAttribute(a:attributes)
	let result=fnamemodify(aTagFile,":h").'/'.aFile
	return result
endfunction "}}}1

function! s:GetExCommand( attributes ) "{{{1
	return s:GetAttribute (a:attributes,'excmd')
endfunction "}}}1

function! s:GetFileAttribute ( attributes ) "{{{1
	return s:GetAttribute (a:attributes,'file')
endfunction "}}}1

function! s:GetOutterClassAttribute ( attributes ) "{{{1
	let kind=s:GetKind(a:attributes)
	let result=substitute (kind,".*\tclass:\\(\\i\\+\\).*",'\1','')
	if kind==result
		let result=''
	endif
	return result

endfunction "}}}1

function! s:GetAttribute ( attributes,name ) "{{{1
	let result=substitute (a:attributes,".*@".a:name."=\\([^@]*\\).*",'\1','')
	if result==a:attributes 
		let result=''
	endif 
	return result
endfunction "}}}1

function! s:GetKind ( attributes ) "{{{1
	let result=substitute (a:attributes,"^\\([^@]*\\)@.*",'\1','')
	if result==a:attributes 
		let result=''
	endif 
	return result
endfunction "}}}1

function! s:GetTagFileAttribute ( attributes ) "{{{1
	return s:GetAttribute (a:attributes,'tagfile')
endfunction "}}}1

function! s:GetAttributes (path) "{{{1
	return substitute(a:path,".*<\\([^>]*\\)>$" ,"\\1",'')
endfunction "}}}1

function! s:GetPath(path) "{{{1
	return substitute(a:path,"<\\([^>]*\\)>" ,'','g')
endfunction "}}}1

