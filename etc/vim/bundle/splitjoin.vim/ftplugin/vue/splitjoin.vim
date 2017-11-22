let b:splitjoin_split_callbacks = [
      \ 'sj#html#SplitTags',
      \ 'sj#html#SplitAttributes',
      \ 'sj#css#SplitDefinition',
      \ 'sj#css#SplitMultilineSelector',
      \ 'sj#js#SplitFatArrowFunction',
      \ 'sj#js#SplitArray',
      \ 'sj#js#SplitObjectLiteral',
      \ 'sj#js#SplitFunction',
      \ 'sj#js#SplitOneLineIf',
      \ 'sj#js#SplitArgs'
      \ ]

let b:splitjoin_join_callbacks = [
      \ 'sj#html#JoinAttributes',
      \ 'sj#html#JoinTags',
      \ 'sj#css#JoinDefinition',
      \ 'sj#css#JoinMultilineSelector',
      \ 'sj#js#JoinFatArrowFunction',
      \ 'sj#js#JoinArray',
      \ 'sj#js#JoinArgs',
      \ 'sj#js#JoinFunction',
      \ 'sj#js#JoinOneLineIf',
      \ 'sj#js#JoinObjectLiteral',
\ ]
