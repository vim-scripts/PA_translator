" Vim global plugin for translating unknown words, sentences
" Last Change:	2010 January 20
" Maintainer:	Pukalskyy Andrij <andrijpu@gmail.com>

" ensure that plugin is loaded just one time
if exists("g:PA_translator_version")
    finish
endif
let g:PA_translator_version = "0.0.4"

" check for Vim version 700 or greater
if v:version < 700
  echo "Sorry, PA_translator ".g:PA_translator_version."\nONLY runs with Vim 7.0 and greater."
  finish
endif

" plugin needs your vim was compiled with ruby support
if !has('ruby')
  echo "Sorry, PA_translator ".g:PA_translator_version."\nONLY runs if Vim was compiled with RUBY support."
  finish
endif

" save previous `cpo` value. it is necessary for `compatible` mode
let s:save_cpo = &cpo
set cpo&vim

" global script variables
if !exists("g:PA_translator_printed_in_encoding")
    let g:PA_translator_printed_in_encoding = &encoding
endif
if !exists("g:PA_translator_received_in_encoding")
    let g:PA_translator_received_in_encoding = 'cp1251'
endif
if !exists("g:PA_translator_from_lang")
    let g:PA_translator_from_lang = 'en'
endif
if !exists("g:PA_translator_to_lang")
    let g:PA_translator_to_lang = 'uk'
endif

" should be initialized before 1-st translating actions
function! PA_translator_init()
ruby<<EOF
    require 'cgi'
    require 'iconv'

    def PA_translate_by_google(word_or_sentence)
        VIM::message("Wait while translating is performing...")

        # ruby-vim does not allow to HTTP-get by host name. Just by IP.
        # On the other hand translate.google.com ignore IPs.
        # This hack resolve this problem.
        host = "translate.google.com"
        path = "/translate_a/t?client=t&text=%s&sl=%s&tl=%s&otf=2&pc=0"% [CGI.escape(word_or_sentence.strip),
                                                                          VIM::evaluate('g:PA_translator_from_lang'),
                                                                          VIM::evaluate('g:PA_translator_to_lang') ]
        cmd = "require 'net/http'; p Net::HTTP.get('%s', '%s')"% [host, path]
        begin
            response = `ruby -e "#{cmd}"`
        rescue
            VIM::message("It seems you should connect to internet!!!")
        else
            # porting JSON to hash without including additional JSON library
            response_as_arr = eval(eval(response.gsub('":\"', '"=>\"')).gsub('":[', '"=>[').gsub('":{', '"=>{'))

            VIM::message("Translated.")
            VIM::message('='*40)

            # encoding convertor
            encode_conv = Iconv.new(VIM::evaluate("g:PA_translator_printed_in_encoding"), VIM::evaluate("g:PA_translator_received_in_encoding"))

            # print translation
            response_as_arr["sentences"].each do |sentence|
                VIM::message(encode_conv.iconv(sentence["trans"]))
            end

            # print gender cases
            response_as_arr["dict"].each do |gender|
                VIM::message(encode_conv.iconv(gender["pos"]))
                gender["terms"].each { |term| VIM::message("    %s"% [encode_conv.iconv(term), ]) }
            end if response_as_arr.has_key? "dict"
        end
    end
EOF
endfunction

" translate just 1 word under cursor in normal mode
function! PA_translate_word()
ruby<<EOF
    PA_translate_by_google(VIM::evaluate("expand('<cword>')"))
EOF
endfunction

" translate selected sentence in visual mode
function! PA_translate_sentence()
ruby<<EOF
    PA_translate_by_google(VIM::evaluate("substitute(@0, '\n', '', 'g')"))
EOF
endfunction


:call PA_translator_init()

let mapleader = ','
if !hasmapto('<Esc>:call<Space>PA_translate_word()<CR>')
    nnoremap <Leader>tr <Esc>:call<Space>PA_translate_word()<CR>|        " it translates 1 word in NORMAL mode
endif
if !hasmapto('Y<Esc>:call<Space>PA_translate_sentence()<CR>')
    vnoremap <Leader>tr Y<Esc>:call<Space>PA_translate_sentence()<CR>|   " it translates sentence selected or under cursor line in VISUAL mode
endif


" restore `cpo` value for other modules
let &cpo = s:save_cpo
