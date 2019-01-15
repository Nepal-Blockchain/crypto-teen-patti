// Allows us to use ES6 in our migrations and tests.
require('babel-register')

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '8848',
      gasPrice: 5000000000
    },
    rinkeby: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '4',
      gasPrice: 5000000000
    }
  },
  solc: {
    version:'0.5.0',
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
}
