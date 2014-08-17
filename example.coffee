x = (param)-->
  console.log param
  yield 'a'
  y = yield 'b'
  console.log "result:", y
  yield 'c'
  return 'end'

g = x('hello world')

console.log g.next() # 'a'
console.log g.next() # 'b'
# pass arg as return of 2nd yield;
console.log g.next({prop: 'foobar'}) # 'c'
console.log g.next() # 'end'