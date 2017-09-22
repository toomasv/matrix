Red [
	Author: "Toomas Vooglaid"
	Date: 7-9-2017
	Last-update: 22-9-2017
]
mx: context [
	ctx: self
	mtx: object [
		rows: cols: data: none
		get-col: func [col][extract at data col cols]
		get-row: func [row][copy/part at data row - 1 * cols + 1 cols]
		remove-row: func [row][remove/part at data get-idx row 1 cols rows: rows - 1 show]
		remove-col: func [col][
			loop rows [data: remove skip data cols - 1]
			data: head data cols: cols - 1 show
		]
		get-idx: func [row col][index? at data row - 1 * cols + col]
		get-at: func [row col][pick data row - 1 * cols + col]
		to-float: does [forall data [data/1: system/words/to-float data/1]]
		swap-dim: has [c][c: cols cols: rows rows: c]
		square?: does [rows = cols]
		symmetric?: has [d][transpose d: copy data transpose equal? data d]
		diagonal?: function [][
			either square? [
				repeat i cols [
					repeat j rows [
						if (i <> j) and (0 <> get-at i j) [return false]
				]] 
				true
			][false]
		]
		zero?: does [0 = ctx/summa data]
		sub-exclude: func [rs cs /local m2][ ; TBD
			m2: copy self
			switch type?/word rs [
				block! [
					sort/reverse rs
					forall rs [
						remove
					]
				]
				integer! []
				none! []
			]
			switch type?/word cs [
				block! []
				integer! []
				none! []
			]
		]
		transpose: does [ctx/transpose self]
		rotate: func [n][ctx/rotate n self]
		show: does [new-line/skip copy data true cols]
		pretty: function [][;/bar /local d i col-lengths][
			col-lengths: copy []
			repeat i cols [
				c: copy get-col i
				c: sort/compare c func [a b][(length? form a) > (length? form b)]
				append col-lengths length? form first c
			]
			cols2: copy []
			templ: copy []
			letters: "abcdefghijklmnopqrstuvwyz" 
			repeat n cols [
				append cols2 to-word pick letters n
				append templ compose [
					pad/left (to-word pick letters n) (pick col-lengths n) 
					;(either bar and (n < cols) ["│"][""])⎡⎢⎤⎣⎥⎦  ⎾⏋⎿⏌  ⌈⌉⌊⌋
				]
			]
			step: (summa col-lengths) + cols - 1 
			print [#"┌" pad #" " step #"┐"]
			foreach (cols2) data [
				print [#"│" reduce compose templ #"│"]
			]
			print [#"└" pad #" " step #"┘" #"^/"]
		]
		get-diagonal: func [i dir /local out][
			data: skip data i - 1 
			set [comp inc] switch dir [r [0 :+] l [1 :-]]
			out: collect [
				while [not tail? data][
					keep data/1 
					data: case [
						all [dir = 'r 0 = ((index? data) % cols)] [next data]
						all [dir = 'l 1 = ((index? data) % cols)] [skip data 2 * cols - 1]
						true [skip data cols + either dir = 'r [1][-1]]
					]
				]
			]
			data: head data
			out
		]
		swap-rows: func [r1 r2][ctx/swap-rows r1 r2 self]
		determinant: does [ctx/determinant self]
		trace: does [ctx/trace self]
		identity: func [/side d][either side [ctx/identity/side self d][ctx/identity self]]
		split-col: func [col][ctx/split-col col self]
	]
	vector-op: func [op a b /local i][
		case [
			all [number? a number? b]	[return either op? :op [a op b][op a b]]
			all [number? a any-block? b][forall b [b/1: either op? :op [a op b/1][op a b/1]] return b]
			all [any-block? a number? b][forall a [a/1: either op? :op [a/1 op b][op a/1 b]] return a]
			all [any-block? a any-block? b][
				either (length? a) = (length? b) [
					forall a [i: index? a a/1: either op? :op [a/1 op pick b i][op a/1 pick b i]]
					return a
				][
					cause-error 'user 'message ["Vectors must be of the same length!"]
				]
			]
		]
	]
	product: func [blk /local out][out: 1 forall blk [out: out * blk/1] out]
	summa: func [blk /local out][out: 0 forall blk [out: out + blk/1] out]
	determinant: func [m /local i r l][
		either m/square? [
			switch/default m/cols [
				0	[1]
				1	[m/data/1]
				2 	[math [m/data/1 * m/data/4 - m/data/2 * m/data/3]]
			][
				r: make block! m/cols l: make block! m/cols
				repeat i m/cols [
					insert r product m/get-diagonal i 'r
					insert l product m/get-diagonal i 'l
				]
				(summa r) - (summa l)
			]
		][
			cause-error 'user 'message ["Matrix must be square to find determinant!"]
		]
	]
	trace: func [m][
		either m/square? [
			summa m/get-diagonal 1 'r
		][
			cause-error 'user 'message ["Trace is defined for square matrices only!"]
		]
	]
	add: func [op m1 m2][
		either all [m1/cols = m2/cols m1/rows = m2/rows][;length? m1/data length? m2/data [ 
			repeat i length? m1/data [m1/data/:i: m1/data/:i op m2/data/:i]
		][
			cause-error 'user 'message ["Matrices of unequal dimensions!"]
		]
		m1
	]
	multi: func [m1 m2 /local m3 val i j k l][
		either equal? l: m1/cols m2/rows [
			m3: make mtx [rows: m1/rows cols: m2/cols data: make block! (m1/rows * m2/cols)]
			repeat i m1/rows [
				repeat j m2/cols [
					val: 0
					repeat k l [val: (m1/get-at i k) * (m2/get-at k j) + val]
					append m3/data val
				]
			]
		][
			cause-error 'user 'message ["Dimensions don't match in multiplication!"]
		]
		m3
	]
	kronecker: func [m1 m2 /local m3 i j k l][
		m3: make mtx [rows: m1/rows * m2/rows cols: m1/cols * m2/cols data: make block! rows * cols]
		repeat i m1/rows [
			repeat j m2/rows [
				repeat k m1/cols [
					repeat l m2/cols [
						append m3/data (m1/get-at i k) * (m2/get-at j l)
		]]]]
		m3
	]
	transpose: func [m /local d i j r c][
		d: copy []
		repeat i c: m/cols [repeat j r: m/rows [append d m/get-at j i]]
		m/cols: r m/rows: c	m/data: d
		m
	]
	rotate: func [n [integer!] m /local data i][
		data: copy []
		switch n [
			1 or -3 [repeat i m/cols [append data copy reverse m/get-col i] m/swap-dim]
			2 or -2 [repeat i m/rows [append data reverse copy m/get-row m/rows + 1 - i]]
			3 or -1 [repeat i m/cols [append data copy m/get-col m/cols + 1 - i] m/swap-dim]
		]
		m/data: data 
		m
	]
	swap-rows: func [r1 r2 m /local tmp][
		tmp: m/get-row r1 
		change/part at m/data r1 - 1 * m/cols + 1 m/get-row r2 m/cols 
		change/part at m/data r2 - 1 * m/cols + 1 tmp m/cols 
		m
	]
	identity: func [m /side d /local i][
		d: either side [switch d ['l ['rows] 'r ['cols]]]['rows]
		m/square?
		either (side or m/square?) [
			data: make block! power m/:d 2
			repeat i m/:d [repeat j m/:d [append data either i = j [1][0]]]
			make mtx compose [cols: (m/:d) rows: (m/:d) data: (reduce [data])] 
		][
			cause-error 'user 'message [
				{You need to determine /side ['l | 'r] for non-square matrix!}
			]
		]
	]
	augment: func [m1 m2 /local i j][
		either m1/rows = m2/rows [
			repeat i m1/rows [
				k: m1/rows - i + 1
				j: m1/get-idx k m1/cols + 1
				insert at m1/data j m2/get-row k
			]
			m1/cols: m1/cols + m2/cols
		][
			cause-error 'user 'message ["Augmented matrix must have same number of rows as the other!"]
		]
		m1
	]
	rref: func [n /local m i j c val][
		m: copy/deep n m/to-float
		repeat i m/rows [
			; make the pivot
			if 0 = m/get-at i i [
				c: at m/get-col i i + 1
				until [
					c: next c 
					if tail? c [
						cause-error 'user 'message ["Impossible to get reduced row eschelon form!"]
					] 
					0 < first c
				]
				swap-rows i index? c 
			]
			; reduce it to 1
			if 1 <> val: m/get-at i i [
				change/part at m/data m/get-idx i 1 vector-op :/ m/get-row i val m/cols
			]
			; reduce other rows at this column to 0 
			repeat j m/rows [
				if all [j <> i 0 <> c: m/get-at j i][
					change/part at m/data m/get-idx j 1 vector-op :- m/get-row j vector-op :* c m/get-row i m/cols
				]
			]
		]
		m
	]
	split-col: func [col m /local data i j cls][
		data: copy []
		cls: m/cols - col + 1
		repeat i m/rows [
			j: m/rows - i + 1
			insert data take/part at m/data m/get-idx j col cls 
		] 
		m/cols: col - 1
		reduce [m make mtx compose/deep [rows: (m/rows) cols: (cls) data: [(data)]]]
	]
	invert: func [m /local n][
		augment m identity m
		n: rref m
		m: first split-col m/rows + 1 m
		second split-col n/rows + 1 n
	]
	
	ops-rule: ['+ | '- | '* | '/ | '% | '** | '>> | '<< | '>>> | 'and | 'or | 'xor | 'div | 'x | 'augment]

	set 'matrix func [spec /local dim dims rule result m w m1 m2 op op' var vars ops unary unaries d matrices][
		vars: copy [] ops: copy [] matrices: copy [] unaries: copy []
		matrix-rule: [(m: none)[
			set dim pair! [set mdata block! | set w word! if (block? get/any w)(mdata: get w)] 
			(either (dim/1 * dim/2) = length? mdata: reduce mdata [
				m: make mtx [rows: dim/1 cols: dim/2 data: mdata]
			][
				cause-error 'user 'message ["Data length does not match dimensions!"]
			]
			)
		|	set w word! if (object? get/any w)(set w m: make mtx get w)
		| 	set m number!
		]	(insert matrices m)]
		unary-rule: [
			set unary [
				'transpose 
			| 	'rotate set n integer! 
			| 	'swap copy dims 3 skip 
			| 	'determinant
			|	'trace
			| 	'invert
			| 	'rref
			|	'identity opt [set d ['l | 'r]] 
			](
				insert unaries switch/default unary [
					rotate [reduce [unary n]] 
					swap [reduce [unary dims]]
					identity [either d [reduce [unary d]][unary]]
				][unary] 
			) expr-rule (
				unary: take unaries 
				switch unary [
					rotate [n: take unaries]
					swap [dims: take unaries]
					identity [if find ['l 'r] first unaries [d: take unaries]]
				]
				switch/default unary [
					rotate [self/rotate n matrices/1]
					;swap [matrices/1/(to-word rejoin ["swap-" dims/1]) dims/2 dims/3]
					swap [self/(to-word rejoin ["swap-" dims/1]) dims/2 dims/3 matrices/1]
					trace [insert matrices self/trace matrices/1]
					determinant [insert matrices self/determinant matrices/1]
					identity [insert matrices either d [
						self/identity/side matrices/1 d
					][
						self/identity matrices/1
					]]
					rref [insert matrices self/rref matrices/1]
					invert [insert matrices self/invert matrices/1]
				][
					self/:unary matrices/1
				]
			)
		]
		op-probe: [ahead [[pair! [block! | word!] | word!] ops-rule]]
		op-rule: [
			matrix-rule set op' ops-rule (insert ops op') expr-rule (
				op': take ops set [m2 m1] take/part matrices 2
				case [
					op' = 'div [op: :/ either number? m1 [m1: to-float m1][m1/to-float]]
					find [x augment] op' []
					true [op: get op']
				]
				case [
					all [number? reduce m1 number? reduce m2] [m1: (reduce m1) op reduce m2]
					number? reduce m1 [data: m2/data forall data [data/1: (reduce m1) op data/1] m1: m2]
					number? reduce m2 [data: m1/data forall data [data/1: data/1 op reduce m2]]
					true [case [
						find exclude ops-rule ['x 'augment] op' [m1: self/add :op m1 m2]
						(same? op' 'x) or (same? op' '×) [m1: self/multi m1 m2]
						same? op' 'X [m1: self/kronecker m1 m2]
						op' = 'augment [m1: self/augment m1 m2]
					]]
				]
				insert matrices m1
			)
		]
		expr-rule: [
			set var set-word! (insert vars var) 
			expr-rule (var: take vars set var copy matrices/1)
		|	ahead block! into rule 
		|	op-probe op-rule
		|	unary-rule
		| 	matrix-rule
		]
		parse spec rule: [some [
			ahead paren! into rule
		| 	expr-rule
		|	s: print ["No rule applied at: " :s]
		]]
		
		either number? m1: take matrices [m1][new-line/skip copy m1/data true m1/cols]
	]
]
