" Vim syntax file

" Please check :help java.vim for comments on some of the options available.

" Quit when a syntax file was already loaded
if !exists("main_syntax")
  if version < 600
    syntax clear
  elseif exists("b:current_syntax")
    finish
  endif
  " we define it here so that included files can test for it
  let main_syntax='jexplorer'
endif

	syn match JPackage "\<\w\+\>\ze<p.*$"
	syn match JClass "\<\w\+\>\ze<c.*$"
	syn match JMethod "\<\w\+\>\ze<m.*$"
	syn match JField "\<\w\+\>\ze<f.*$"
	syn match JInterface "\<\w\+\>\ze<i.*$"
	syn match JNode "^\s*[+-]"

	"syn match JPublic "\<\w\(\w.*<.*:access=public\>[^>]*>\)\@="
	"syn match JProtected "\<\w\(\w.*<.:protected\>[^>]*>\)\@="
	"syn match JPrivate "\<\w\(\w.*<.:private\>[^>]*>\)\@="

	syn match JHide "<[^>]*>"
	hi link JPackage String 
	hi link JMethod Function 
	hi link JField  Label
	hi link JInterface  Question
	hi link JNode  Comment
	hi JInterface gui=Italic guifg=LightGreen
	hi JPublic  guifg=Green guibg=NONE
	hi JProtected  guifg=Blue guibg=NONE
	hi JPrivate  guifg=DarkRed guibg=NONE
	hi link JHide Ignore
	hi link JClass Type
