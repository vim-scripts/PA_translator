" Vim global plugin for translating unknown words, sentences
" Last Change:	2009 Apr 15
" Maintainer:	Pukalskyy Andrij <andrijpu@gmail.com>

" ensure that plugin is loaded just one time
if exists("g:PA_translator_version")
    finish
endif
let g:PA_translator_version = "0.0.1"

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

" save previous `cpo` value. it is neccasery for `compatible` mode
let s:save_cpo = &cpo
set cpo&vim

" global script varibles
let g:PA_translator_printed_in_encoding = &encoding
let g:PA_translator_received_in_encoding = 'koi8-r'
if !exists("g:PA_translator_from_lang")
    let g:PA_translator_from_lang = 'en'
endif
if !exists("g:PA_translator_to_lang")
    let g:PA_translator_to_lang = 'uk'
endif

" should be initialized before 1-st translating actions
function! PA_init_translator()
ruby<<EOF
    require 'net/http'
    require 'cgi'
    require 'iconv'

    def translate_word(word)
        response = eval(Net::HTTP.get("209.85.171.100", "/translate_a/t?client=t&" <<
                                                        "sl=#{VIM::evaluate('g:PA_translator_from_lang')}&" <<
                                                        "tl=#{VIM::evaluate('g:PA_translator_to_lang')}&" <<
                                                        "text=#{CGI.escape(word)}"))
        encode_conv = Iconv.new(VIM::evaluate("g:PA_translator_printed_in_encoding"), VIM::evaluate("g:PA_translator_received_in_encoding"))
        unless response.class == Array
            VIM::message("The `#{word}` can not be transalted")
        else
            VIM::message(encode_conv.iconv(response[0]))
            VIM::message("=" * 100)
            response[1].each do |word_by_gender|
                VIM::message(encode_conv.iconv(word_by_gender[0]))
                word_by_gender[1, word_by_gender.size].uniq.each {|word| VIM::message("    #{encode_conv.iconv(word)}")}
            end
        end
    end

    def translate_sentence(sentence)
        response = eval(Net::HTTP.get("209.85.171.100", "/translate_a/t?client=t&" <<
                                                        "sl=#{VIM::evaluate('g:PA_translator_from_lang')}&" <<
                                                        "tl=#{VIM::evaluate('g:PA_translator_to_lang')}&" <<
                                                        "text=#{CGI.escape(sentence)}"))
        encode_conv = Iconv.new(VIM::evaluate("g:PA_translator_printed_in_encoding"), VIM::evaluate("g:PA_translator_received_in_encoding"))
        VIM::message(encode_conv.iconv(response))
    end
EOF
endfunction

" translate just 1 word under cursor in normal mode
function! PA_translate_word()
ruby<<EOF
    translate_word(VIM::evaluate("expand('<cword>')"))
EOF
endfunction

" translate selected sentence in visual mode
function! PA_translate_sentence()
ruby<<EOF
    translate_sentence(VIM::evaluate("substitute(@0, '\n', '', 'g')"))
EOF
endfunction


:call PA_init_translator()
nnoremap <A-Space> <Esc>:call<Space>PA_translate_word()<CR>|        " it translates 1 word in NORMAL mode
vnoremap <A-Space> Y<Esc>:call<Space>PA_translate_sentence()<CR>|   " it translates sentence selected or under cursor line in VISUAL mode


" restore `cpo` value for other modules
let &cpo = s:save_cpo
