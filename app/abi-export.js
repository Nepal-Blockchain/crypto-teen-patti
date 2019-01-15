const fs = require('fs')

const artifact = require('../build/contracts/TeenPatti.json')
let TeenPatti = {}
TeenPatti.networks = {}
TeenPatti.abi = artifact.abi
console.log('NETWORK                ADDRESS                                                    HASH')
for (const key in artifact.networks) {
  if (artifact.networks.hasOwnProperty(key)) {
    console.log(key, ' -- ', artifact.networks[key].address, ' -- ', artifact.networks[key].transactionHash)
    TeenPatti.networks[key] = artifact.networks[key]
  }
}
fs.writeFile('./app/TeenPatti.json', JSON.stringify(TeenPatti), (err) => {
  if (err) {
    console.error(err)
  }
})
