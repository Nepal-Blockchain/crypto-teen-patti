var Core = artifacts.require('./TeenPatti.sol')
let x = 1
let y = 1
let z = 1
let C = (a, q, k) => {
  return (a === q || q === k)
    ? (a === k)
      ? 11 : 2
    : (a === 1)
      ? (q === 2 && k === 3)
        ? 7 : (q === 12 && k === 13)
          ? 6 : 1
      : (a + 1 === q && q + 1 === k)
        ? 5 : 1
}
let h = (g, h, i) => {
  it(`should check card ${g},${h},${i} = state ${C(g, h, i).valueOf()}`, () => {
    return Core.deployed().then((core) => {
      return core.read(g, h, i)
    }).then((stat) => {
      assert.equal(stat.toNumber(), C(g, h, i).valueOf(), `Game core status mismatch`)
    })
  })
}

contract('Core', function (accounts) {
  for (; x < 14; x++) {
    if (y > 13) {
      y = x
    }
    for (; y < 14; y++) {
      if (z > 13) {
        z = y
      }
      for (; z < 14; z++) {
        h(x, y, z)
      }
    }
  }
})
