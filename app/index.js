import './styles/app.css'
import {
  default as Web3
} from 'web3'
import ABI from './TeenPatti.json'
let infura, infura2, accounts, account, _hash
let net
let stat = [
  'NOT READY', // Win X Rewards @ 1x bet 0
  'HIGH CARD', // 2.0000000 1
  'PAIR CARD', // 2.1666667 2
  'FLUSH CARD', // 2.2500000 3
  'FLUSH PAIR', // 2.3333333 4
  'SEQUENCE', // 2.4166667 5
  'TOP SEQUENCE', // 2.5000000 6
  'BOTTOM SEQUENCE', // 2.5833333 7
  'PURE SEQUENCE', // 2.6666667 8
  'PURE TOP', // 2.7500000 9
  'PURE BOTTOM', // 2.8333333 10
  'PRIAL CARD', // 2.9166667 11
  'PURE PRIAL' // 3.0000000 12
]
console.log(stat)
const App = {
  TeenPatti: {},
  state: {},
  networkCheck: async () => {
    let but = document.getElementById('playButton')
    try {
      App.netID = await web3.eth.net.getId()
      if (App.netID == 4 && !infura2) {
        but.disabled = false
        App.TeenPatti = new web3.eth.Contract(ABI.abi, ABI.networks[App.netID].address)
      }
      //if ((ABI.networks).hasOwnProperty(App.netID)) {
      let tx = await infura.eth.getTransaction(ABI.networks[4].transactionHash)
      //if (tx !== null) {
      App.deployBlock = tx.blockNumber
      accounts = await web3.eth.getAccounts()
      if (accounts.length === 0 || App.netID != 4) {
        accounts[0] = '0xC0FFeE9d5c668307C6D0493d2DeC02BF8dB17292'
        App.onError('Please Download Metamask Plugin.<br>Make sure your Ethereum client/MetaMask is configured to use Rinkeby Testnet.')
      }
      App.accounts = accounts
      account = accounts[0]
      App.iPatti = new infura.eth.Contract(ABI.abi, ABI.networks[4].address)
      App.refreshBalance()
      document.getElementById('userAddr').innerHTML = account
      App.update()
      App.logBook()
      App.estimatePlay()
      //}
      //}

      //App.onError('Contract not deployed on network ' + net + '<br> Download Metamask plugin & switch to Rinkeby Testnet')
    } catch (e) {
      App.onError(e)
    }
  },
  start: async () => {
    try {
      await App.networkCheck()
    } catch (e) {
      App.onError(e)
    }
  },
  fixText: (txt) => {
    txt = txt.slice(0, 9) + '..' + txt.slice(txt.length - 6)
    return txt
  },
  cbx: async (_id) => {
    let gameData = await App.iPatti.methods.getGameData(_id).call()
    let x = document.getElementById(`callback_${_id}`)
    if (x != null) {
      x.setAttribute('title', gameData.callback)
      x.innerHTML = `<a target="_blank" href="http://app.oraclize.it/home/check_query?id=${(gameData.callback).slice(2, (gameData.callback).length)}">${(gameData.callback)}</a>`
    }
  },
  toSzabo: (unit) => {
    return (web3.utils.fromWei(unit, 'szabo') * 1).toFixed(3)
  },
  toWei: (unit) => {
    return web3.utils.toWei(unit, 'szabo')
  },
  logBook: () => {
    let tab = document.getElementById('logBook')
    App.GameLog = App.iPatti.events.NewGame({
        fromBlock: App.deployBlock,
        toBlock: 'latest'
      })
      .on('data', (event) => {
        let _m = event.returnValues
        let tr = document.getElementById(`game_${_m.gameID}`)
        if (tr == null) {
          tr = document.createElement('tr')
          tr.setAttribute('id', `game_${_m.gameID}`)
          tr.classList.add('trx')
          // tr.setAttribute('onclick', `alert(${_m.gameID});`)
          tr.style.backgroundColor = '#878700'
        }
        tr.innerHTML = `
        <td >${_m.gameID}</td>
        <td ${_m._addr == App.accounts[0] ? 'style="background-color:#008787;"' : ''} title="${_m._addr}">${(_m._addr)}</td>
        <td>${_m._side ? 'LOW' : 'HIGH'}<br>${App.toSzabo(_m._bet)}</td>
        <td id="houseCard_${_m.gameID}" class="tinyCard">
        <i class="card_0_0"></i><i class="card_0_0"></i><i class="card_0_0"></i>
        </td>
        <td id="playerCard_${_m.gameID}" class="tinyCard">
        <i class="card_0_0"></i><i class="card_0_0"></i><i class="card_0_0"></i>
        </td>
        <td id="result_${_m.gameID}">..</td>
        <td id="callback_${_m.gameID}">..</td>
        <td id="random_${_m.gameID}">..</td>`
        if (tab.rows.length > 20) {
          tab.deleteRow(tab.rows.length - 1)
        }
        tab.prepend(tr)
        App.cbx(_m.gameID)
      })
      .on('error', App.onError)

    App.Result = App.iPatti.events.Result({
        fromBlock: App.deployBlock,
        toBlock: 'latest'
      })
      .on('data', async (event) => {
        let _m = event.returnValues
        let game = document.getElementById(`game_${_m.gameID}`)
        let house = document.getElementById(`houseCard_${_m.gameID}`)
        let player = document.getElementById(`playerCard_${_m.gameID}`)
        let random = document.getElementById(`random_${_m.gameID}`)
        let result = document.getElementById(`result_${_m.gameID}`)
        if (game != null) {
          let cards = await App.iPatti.methods.getCardsByGID(_m.gameID, false).call()
          house.innerHTML = ''
          player.innerHTML = ''
          house.setAttribute('title', stat[cards._stats[1]])
          player.setAttribute('title', stat[cards._stats[0]])
          for (let i = 0; i < 3; i++) {
            house.innerHTML += `<i class="card_${cards.hands[1][i].suit}_${cards.hands[1][i].rank}"></i>`
            player.innerHTML += `<i class="card_${cards.hands[0][i].suit}_${cards.hands[0][i].rank}"></i>`
          }
          house.innerHTML += `<br><b class ="stats">(${cards._stats[1]}) ${stat[cards._stats[1]]}</b>`
          player.innerHTML += `<br><b class ="stats">(${cards._stats[0]}) ${stat[cards._stats[0]]}</b>`
          if (_m._gg == 1) {
            game.style.backgroundColor = '#ff000060'
            result.innerHTML = 'LOSE<br>' + App.toSzabo(_m._amount)
          } else if (_m._gg == 2) {
            game.style.backgroundColor = 'ff000060'
            result.innerHTML = 'DRAW<br>' + App.toSzabo(_m._amount)
          } else {
            result.innerHTML = 'WIN<br>' + App.toSzabo(_m._amount)
            game.style.backgroundColor = ''
          }
          let gameData = await App.iPatti.methods.getGameData(_m.gameID).call()
          random.setAttribute('title', '0x' + gameData.random)
          random.innerHTML = ('0x' + gameData.random)
        }
      })
      .on('error', App.onError)
  },
  update: () => {
    try {
      infura.eth.subscribe('newBlockHeaders', (err, block) => {
        if (err) {
          throw (err)
        }
        App.refreshBalance()
        App.estimatePlay()
        App.latestBlock = block.number
      })
    } catch (e) {
      App.onError(e)
    }
  },
  onError: (e) => {
    console.error(e)
    App.setStatus(e)
  },
  setStatus: (message) => {
    document.getElementById('status').innerHTML = message
  },
  refreshBalance: async () => {
    try {
      document.getElementById('balance').innerHTML = App.toSzabo(await infura.eth.getBalance(account))
      document.getElementById('gameBal').innerHTML = App.toSzabo(await infura.eth.getBalance(ABI.networks[4].address))
      document.getElementById('minBet').innerHTML = App.toSzabo(await App.iPatti.methods.minPrice().call())
      document.getElementById('maxBet').innerHTML = App.toSzabo(await App.iPatti.methods.maxPrice().call())
      document.getElementById('pendBet').innerHTML = App.toSzabo(await App.iPatti.methods.pending().call())
      let totalWins = await App.iPatti.methods.totalWins().call()
      let totalGames = await App.iPatti.methods.totalGames().call()

      document.getElementById('winGame').innerHTML = totalWins
      document.getElementById('totalGames').innerHTML = totalGames
      document.getElementById('winLoss').innerHTML = ((totalWins / totalGames) * 100).toFixed(4) + '%'
    } catch (e) {
      App.onError(e)
    }
  },
  estimatePlay: () => {
    let amount = document.getElementById('playAmount').value
    let gas = document.getElementById('playGas').value
    let side = document.getElementsByName('side')
    let estGas = document.getElementById('estGas')
    try {
      App.iPatti.methods.play(!side[0].checked).estimateGas({
        from: account,
        gasPrice: gas * 1000000000,
        value: web3.utils.toWei(amount, 'szabo')
      }).then((est) => {
        console.log('gas', est)
        estGas.innerHTML = App.toSzabo((est * gas * 1000000000).toString())
      })
    } catch (e) {
      App.onError(e)
    }
  },
  play: () => {
    App.estimatePlay()
    let amount = document.getElementById('playAmount').value
    let gas = document.getElementById('playGas').value
    let side = document.getElementsByName('side')
    App.setStatus('Initiating transaction... (please wait)')
    console.log(web3.utils.toWei(amount, 'szabo'))
    try {
      App.iPatti.methods.play(!side[0].checked).estimateGas({
        from: account,
        gasPrice: gas * 1000000000,
        value: web3.utils.toWei(amount, 'szabo')
      }).then((est) => {
        App.TeenPatti.methods.play(!side[0].checked).send({
            from: account,
            gas: est,
            gasPrice: gas * 1000000000,
            value: web3.utils.toWei(amount, 'szabo')
          })
          .on('transactionHash', (hash) => {
            App.refreshBalance()
            _hash = hash
            App.state[_hash] = {}
            console.log(hash)
          })
          .on('receipt', (receipt) => {
            // App.state[_hash] = receipt
            console.log('Receipt : ', receipt)
            //let _m = receipt.events.NewGame.returnValues
            App.refreshBalance()
          })
          .on('confirmation', (confirmationNumber, receipt) => {
            App.refreshBalance()
            console.log(confirmationNumber, receipt)
          })
          .on('error', App.onError)
      })
    } catch (e) {
      App.onError(e)
    }
  }
}

window.App = App

window.addEventListener('load', async () => {
  try {
    infura = new Web3(new Web3.providers.WebsocketProvider('wss://rinkeby.infura.io/ws/v3/5070fb8309944f18aa07840da75a9da9'))
    if (window.ethereum) {
      window.web3 = new Web3(ethereum)
      await ethereum.enable()
    } else if (window.web3) {
      window.web3 = new Web3(web3.currentProvider)
    } else {
      infura2 = true
      window.web3 = new Web3(new Web3.providers.WebsocketProvider('wss://rinkeby.infura.io/ws/v3/5070fb8309944f18aa07840da75a9da9'))
    }
    App.start()
  } catch (e) {
    App.onError(e)
  }
})