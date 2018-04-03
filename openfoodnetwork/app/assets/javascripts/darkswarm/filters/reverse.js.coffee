Darkswarm.filter 'reverse', ->
  (input) ->
    result = ''
    input = input or ''
    i = 0
    while i < input.length
      result = input.charAt(i) + result
      i++
    result
