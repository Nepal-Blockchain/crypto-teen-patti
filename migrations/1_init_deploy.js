let TeenPatti = artifacts.require('./TeenPatti')

module.exports = function (deployer) {
  let core
  deployer.deploy(TeenPatti, {
    value: 1000000000000000000
  })
    .then((instance) => {
      core = instance
    }).then(() => {
      return core.setup({
        gas: 3333333
      })
    }).then(() => {
      return core.setup({
        gas: 3333333
      })
    }).then(() => {
      return core.setup({
        gas: 3333333
      })
    }).then(() => {
      return core.setup({
        gas: 3333333
      })
    }).then(() => {
      return core.setup({
        gas: 3333333
      })
    }).then(() => {
      return core.c()
    }).then((c) => {
      console.log('Core Set : ' + c)
    })
}
