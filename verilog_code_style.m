# Вводная часть
## ПОЛЕЗНЫЕ ССЫЛКИ
1. https://sutherland-hdl.com/pdfs/verilog_2001_ref_guide.pdf - Спецификация языка Verilog версии 2001
2. http://fpgacpu.ca/fpga/verilog.html - Verilog Coding Standard - Основной документ по принятому код-стайл'у
3. https://course.cutm.ac.in/wp-content/uploads/2020/06/Lec-4.pdf - Verilog FSM Style - Основной документ по принятому код-стайл'у машин состояний
4. http://socdsp.ee.nchu.edu.tw/class/download/vlsi_dsp_102/night/DSP/Advanced%20Verilog%20coding.pdf - Полезное о Verilog
5. https://www.microsemi.com/document-portal/doc_view/130823-hdl-coding-style-guide - Спецификация языка VHDL
## ПРИНЯТЫЕ СОКРАЩЕНИЯ
 name 				| short 	| _ 	| name 				| short 	| _ 	| name 					| short 
 ---  				| ---   	| --- | ---  				| ---   	| --- | ---  					| --- 	
 acknowledge  | `ack`		| _ 	| error				| `err`		| _ 	| ready					| `rdy`
 adress				| `addr`	| _ 	| enable			| `en`		| _ 	| receive				| `rx`
 arbiter			| `arb`		| _ 	| frame				| `frm`		| _ 	| request				| `req`
 check				| `chk`		| _ 	| generate		| `gen`		| _ 	| resest				| `rst`
 clock				| `clk`		| _ 	| grant				| `gnt`		| _ 	| segment				| `seg`
 config				| `cfg`		| _ 	| increase		| `inc`		| _ 	| source				| `src`
 control			| `ctrl`	| _ 	| input				| `in`		| _ 	| statistic			| `stat`
 counter			| `cnt`		| _ 	| length			| `len`		| _ 	| switcher			| `sf`
 data in			| `din`		| _ 	| output			| `out`		| _ 	| timer					| `tmr`
 data out			| `dout`	| _ 	| packet			| `pkt`		| _ 	| tmporary			| `tmp`
 decode				| `de`		| _ 	| priority		| `pri`		| _ 	| transmit			| `tx`
 decrease			| `dec`		| _ 	| pointer			| `ptr`		| _ 	| valid					| `vld`
 delay				| `dly`		| _ 	| read				| `rd`		| _ 	| write					| `wr`
 disable			| `dis`		| _ 	| read enbale	| `rd_en`	| _ 	| write enable	| `wr_en`
## ПРИНЯТЫЕ ПРЕФИКСЫ
префикс 	| описание						| _ 	| префикс 	| описание						
--- 			| ---									| ---	| --- 			| ---
`g_`			| Generic (VHDL only)	| _ 	| `i_`			| Input signal 
`t_`			| User-Defined Type		| _ 	| `o_`			| Output signal 
`p_`			| Global parameter		| _ 	| `s_`			| Slave interface
_					| _										| _ 	| `m_`			| Master interface
_					|	_										| _ 	| `stat_`		| Statistics interface
_					|	_										| _ 	| `dbg_`		| Debug interface
_					| _										| _ 	| _					| _
`pl_`			| Local patameter			| _ 	| `cnt_`		| Local counter
`w_`			| Local wires					| _ 	| `tick_`		| Local timers
`f_`			| Local flags					| _ 	| `clk_`		| Local clock
`c_`			| Constant 						| _ 	| `r_`			| Local registers
## Общие правила
Основа код стайла принята в соответствии документами по ссылкам `2` и `3`. 
Дополненый/расширен следующими правилами:
- Generics, User-Definedes, Parameters - Пишутся заглавными буквами, не считая пристаки.
- Названия TOP модулей, состоящих из нескольких слов, разделяются `_`.
- Названия второстипенных модулей, состоящих из нескольких слов, пишутся слитно,
	где каждое новое слово пишется с Заглавной буквы.
- Все остальное пишется строчными буквами.
- Любое `if` должно сопровождаться `else`.
- У каждого `CASE` дожен быть `default:`.
- Любое условие должно быть обрамлено в `( )`.
- Любое логическое действие в условиях должно быть обрамлено в `( )`.
- Любое логически завершенное действие необходимо выносить в `f_`, `w_` или `r_`.
- Между логическими операторами/действиями дожен быть один отступ.
- Действия с регистрами, стараться разделять в разные `always`,
  в зависимости от логики/действия/операции, связанные одиним смыслом.
  
P.s. Текст, размещенный на данной странице имеет более высокий приоритет. 
# Ссылка на макет (шаблон)
Следует придерживаться следующему стилю написания кода, как в нижеуказанном примере:
- [verilog_sample.v](/common/fpga/verilog_sample.v)

#### P.s. для подсветки синтаксиса используйте IDE или следующие ссылки:
 - https://coderpad.io/languages/verilog/
 - https://www.edaplayground.com/
 - https://www.tutorialspoint.com/compile_verilog_online.php
 - https://www.jdoodle.com/execute-verilog-online/
 - https://semiconductorclub.com/online-verilog-compiler/