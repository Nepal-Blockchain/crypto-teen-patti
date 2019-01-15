pragma solidity > 0.4 .21;
pragma experimental ABIEncoderV2;

contract OraclizeI {
    address public cbAddress;

    function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns(bytes32 _id);

    function query_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _gaslimit) external payable returns(bytes32 _id);

    function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) public payable returns(bytes32 _id);

    function query2_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _gaslimit) external payable returns(bytes32 _id);

    function queryN(uint _timestamp, string memory _datasource, bytes memory _argN) public payable returns(bytes32 _id);

    function queryN_withGasLimit(uint _timestamp, string calldata _datasource, bytes calldata _argN, uint _gaslimit) external payable returns(bytes32 _id);

    function getPrice(string memory _datasource) public returns(uint _dsprice);

    function getPrice(string memory _datasource, uint gaslimit) public returns(uint _dsprice);

    function setProofType(byte _proofType) external;

    function setCustomGasPrice(uint _gasPrice) external;

    function randomDS_getSessionPubKeyHash() external view returns(bytes32);
}

contract OraclizeAddrResolverI {
    function getAddress() public returns(address _addr);
}

contract usingOraclize {
    uint8 constant networkID_auto = 0;
    OraclizeAddrResolverI public OAR;

    OraclizeI public oraclize;
    modifier oraclizeAPI {
        if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0))
            oraclize_setNetwork();

        if (address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }

    function oraclize_setNetwork() internal returns(bool) {

        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48) > 0) { //rinkeby testnet
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475) > 0) { //ethereum-bridge
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA) > 0) { //browser-solidity
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function oraclize_getPrice(string memory datasource) internal oraclizeAPI returns(uint) {
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string memory datasource, uint gaslimit) internal oraclizeAPI returns(uint) {
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string memory datasource, string memory arg, uint gaslimit) internal oraclizeAPI returns(bytes32 id) {
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice * gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }

    function oraclize_cbAddress() internal oraclizeAPI returns(address) {
        return oraclize.cbAddress();
    }

    function oraclize_setCustomGasPrice(uint gasPrice) internal oraclizeAPI {
        return oraclize.setCustomGasPrice(gasPrice);
    }

    function getCodeSize(address _addr) internal view returns(uint _size) {
        assembly {
            _size: = extcodesize(_addr)
        }
    }
}

library Core {

    struct CORE {
        uint8 a;
        uint8 q;
        uint8 k;
        uint c;
        mapping(uint8 => mapping(uint8 => mapping(uint8 => uint8))) _data;
    }

    function setup(CORE storage _core) internal {
        require(_core.c < 455, "SETUP_COMPLETE");
        uint8 a = _core.a;
        uint8 q = _core.q;
        uint8 k = _core.k;
        uint c = _core.c;
        uint i;
        while (i < 91) { //Setup @ 91 = 5 tx // 65 = 7 tx // 455/13 = 35 // 7 * 5 = 35
            _core._data[a][q][k] =
                (a == q || q == k) ? // is pair ?
                (a == k) ? // is prial 
                11 : 2 : // prial / pair
                (a == 1) ? // top / bot ?
                (q == 2 && k == 3) ? // top ?
                7 : (q == 12 && k == 13) ? // top / bottom?
                6 : 1 : // bot / high 
                (a + 1 == q && q + 1 == k) ? // sequence? 
                5 : 1; // seq/ high

            k++;
            if (k == 14) {
                q++;
                if (q == 14) {
                    a++;
                    q = a;
                }
                k = q;
            }
            c++;
            i++;
        }
        _core.a = a;
        _core.q = q;
        _core.k = k;
        _core.c = c;
    }

    function read(CORE storage _core, uint8 _a, uint8 _q, uint8 _k)
    internal view
    returns(uint8) {
        return _core._data[_a][_q][_k];
    }

    function read(CORE storage _core, uint8[3] memory _hand1, uint8[3] memory _hand2)
    internal view
    returns(uint8[2] memory) {
        return [_core._data[_hand1[0]][_hand1[1]][_hand1[2]], _core._data[_hand2[0]][_hand2[1]][_hand2[2]]];
    }
}

library TP {

    using Core
    for Core.CORE;

    enum RANK {
        BLANK,
        ACE,
        TWO,
        THREE,
        FOUR,
        FIVE,
        SIX,
        SEVEN,
        EIGHT,
        NINE,
        TEN,
        JACK,
        QUEEN,
        KING,
        XACE // high ACE
    }

    enum SUIT {
        SPADE,
        HEART,
        DIAMOND,
        CLUB
    }

    struct CARD {
        SUIT suit;
        RANK rank;
    }

    enum STAT {
        BLANK, //Win X Rewards @ 1x bet 0
        HIGH, //2.0000000 1
        PAIR, //2.1666667 2
        FLUSH, //2.2500000 3
        FPAIR, //2.3333333 4
        SEQ, //2.4166667 5
        TOP, //2.5000000 6
        BOT, //2.5833333 7
        PURE, //2.6666667 8 
        PURET, //2.7500000 9
        PUREB, //2.8333333 10
        PRIAL, //2.9166667 11
        PUREP //3.0000000 12
    }

    enum GG {
        BLANK,
        LOSE,
        DRAW,
        WIN
    }

    struct GAME {
        bool _side;
        uint bet;
        address player;
        bytes32 callback;
        string random;
    }

    function reward(uint _bet, uint8 _stat, uint _min)
    internal pure
    returns(uint _win) {
        return (((_bet * 2) + (_bet * uint(_stat - 1)) / 12) - (_min / 3));
    }

    function randomHash(bytes32 _cbid, string memory _result)
    private pure
    returns(bytes32 _random) {
        // require(bytes(_result).length > 10, "INVALID_LENGTH");
        // in case oraclized random source fails
        return keccak256(abi.encodePacked("Jay Satoshi!!", _cbid, _result));
    }

    function cardGen(bytes32 _cbid, string memory _result)
    internal pure
    returns(CARD[3][2] memory _hands) {
        bytes32 _random = randomHash(_cbid, _result); // use both cb id and random string
        uint deck = uint8(_random[0]) + uint8(_random[31]); // start with 1st + 32nd bytes
        uint8 _card;
        for (uint i = 1; i < 31; i++) {
            deck += uint8(_random[i++]); //1
            deck *= uint8(_random[i++]); //2
            deck -= uint8(_random[i++]); //3
            deck += uint8(_random[i++]); //4
            //deck += uint8(_random[i]); //5
            if (i % 10 == 0) {
                // i = 10, 20, 30 __ 3 cards for P2
                _hands[1][_card] = CARD(SUIT(uint8(_random[i]) % 4), RANK(uint8(deck % 13) + 1));
                _card++;
            } else {
                // i = 5, 15, 25 __ 3 cards for P1
                _hands[0][_card] = CARD(SUIT(uint8(_random[i]) % 4), RANK(uint8(deck % 13) + 1));
            }
        }
    }

    function readStat(Core.CORE storage _core, CARD[3][2] memory _hands) // not sorted
    internal view
    returns(uint8[2] memory _stats, uint8[3][2] memory _ranks) {
        uint8[3] memory _r1 = sortRank(_hands[0][0].rank, _hands[0][1].rank, _hands[0][2].rank);
        uint8[3] memory _r2 = sortRank(_hands[1][0].rank, _hands[1][1].rank, _hands[1][2].rank);

        uint8[2] memory _stat = _core.read(_r1, _r2);

        if (_hands[0][0].suit == _hands[0][1].suit && _hands[0][1].suit == _hands[0][2].suit)
            _stat[0] = flashPower(_stat[0]);

        if (_hands[1][0].suit == _hands[1][1].suit && _hands[1][1].suit == _hands[1][2].suit)
            _stat[1] = flashPower(_stat[1]);

        return (_stat, [_r1, _r2]);
    }

    function cardCompare(uint8[2] memory _stats, uint8[3][2] memory _ranks)
    internal pure
    returns(GG) {
        if (_stats[0] == _stats[1]) { // both players have equal status
            return cardCompare2(_stats[0], _ranks);
        }

        return isWinner(_stats[0], _stats[1]);
    }

    function cardCompare2(uint8 _s, uint8[3][2] memory _ranks)
    private pure
    returns(GG) {
        //stats are equal in this function
        uint8[2] memory _high = [getHigh(_ranks[0]), getHigh(_ranks[1])];
        if (_s < 5) {
            if (_s == 2 || _s == 4) { // special case for pair 
                return finalComp(pairPower(_ranks[0]), pairPower(_ranks[1]));
            } else if (_high[0] == _high[1]) { // high cards are equal                    
                return finalComp(cardPower(_ranks[0]), cardPower(_ranks[1])); // compare 2nd and 3rd 
            }
        }

        return isWinner(_high[0], _high[1]);
    }

    function cardPower(uint8[3] memory _rank)
    private pure
    returns(uint8[2] memory) {
        _rank = acePower(_rank);
        return (_rank[0] == 14) ? ([_rank[2], _rank[1]]) : ([_rank[1], _rank[0]]);
    }

    function pairPower(uint8[3] memory _rank)
    private pure
    returns(uint8[2] memory _r) {
        _rank = acePower(_rank);
        _r[0] = _rank[1]; // pair card
        _r[1] = (_rank[0] == _rank[1]) ? _rank[2] : _rank[0]; // 3rd card
    }


    function acePower(uint8[3] memory _rank)
    private pure
    returns(uint8[3] memory _pow) {
        _pow[0] = (_rank[0] == 1) ? 14 : _rank[0];
        _pow[1] = (_rank[1] == 1) ? 14 : _rank[1];
        _pow[2] = (_rank[2] == 1) ? 14 : _rank[2];
    }

    function finalComp(uint8[2] memory _p1, uint8[2] memory _p2)
    private pure
    returns(GG _win) {
        _win = isWinner(_p1[0], _p2[0]);
        if (_win == GG.DRAW) {
            _win = isWinner(_p1[1], _p2[1]);
        }
    }


    function getHigh(uint8[3] memory _ranks)
    private
    pure returns(uint8) {
        return ((_ranks[0] == 1) ? 14 : _ranks[2]);
    }

    function flashPower(uint8 _stat)
    private pure
    returns(uint8) {
        if (_stat < 3)
            return (_stat + 2);
        else if (_stat < 8)
            return (_stat + 3);

        return 12; //Lucky AF
    }

    function isWinner(STAT _x1, STAT _x2)
    private pure
    returns(GG) {
        return ((_x1 == _x2) ? GG.DRAW : (_x1 > _x2) ? GG.WIN : GG.LOSE);
    }

    function isWinner(uint8 _x1, uint8 _x2)
    private pure
    returns(GG) {
        return ((_x1 == _x2) ? GG.DRAW : (_x1 > _x2) ? GG.WIN : GG.LOSE);
    }

    function sortRank(RANK _r1, RANK _r2, RANK _r3)
    private pure
    returns(uint8[3] memory) {
        if (_r1 > _r3)
            (_r1, _r3) = (_r3, _r1);

        if (_r1 > _r2)
            (_r1, _r2) = (_r2, _r1);

        if (_r2 > _r3)
            (_r2, _r3) = (_r3, _r2);

        return [uint8(_r1), uint8(_r2), uint8(_r3)];
    }

    function sortCards(CARD[3] memory _card)
    private pure
    returns(CARD[3] memory) {

        if (_card[0].rank > _card[2].rank)
            (_card[0], _card[2]) = (_card[2], _card[0]);

        if (_card[0].rank > _card[1].rank)
            (_card[0], _card[1]) = (_card[1], _card[0]);

        if (_card[1].rank > _card[2].rank)
            (_card[1], _card[2]) = (_card[2], _card[1]);

        return _card;
    }

    function sortCards(CARD[3][2] memory _cards)
    internal pure
    returns(CARD[3][2] memory) {
        return [sortCards(_cards[0]), sortCards(_cards[1])];
    }

    function getCards(Core.CORE storage _core, bytes32 _cbid, string memory _random, bool _sort)
    internal view
    returns(CARD[3][2] memory _card, STAT[2] memory _stats) {
        _card = cardGen(_cbid, _random);
        uint8[2] memory _s;
        (_s, ) = readStat(_core, _card);
        if(_sort){
            _card = sortCards(_card);
        }
        return (_card, [STAT(_s[0]), STAT(_s[1])]);
    }

}

contract TeenPatti is usingOraclize {
    using Core
    for Core.CORE;
    using TP
    for * ;

    address public dev;
    Core.CORE internal _core;
    struct Tracker {
        bool active;
        uint totalWins;
        uint totalGames;
        uint pending;
        uint minPrice;
        uint queryGas;
        string queryString;
    }
    Tracker internal _T;
    mapping(uint => TP.GAME) internal game;
    mapping(bytes32 => uint) internal callback2ID;
    event Result(uint indexed gameID, address indexed _addr, TP.GG indexed _gg, uint _amount);
    event NewGame(uint indexed gameID, address indexed _addr, bool _side, uint _bet);

    constructor()
    public
    payable {
        dev = msg.sender;
        _core.a = 1;
        _core.q = 1;
        _core.k = 1;
        _T.pending = 1;
        _T.active = true;        
        _T.queryGas = 111111;
        _T.queryString = "json(https://qrng.anu.edu.au/API/jsonI.php?length=1&type=hex16&size=10).data.0";
    }

    function c()
    public view
    returns(uint) {
        return _core.c;
    }

    function active()
    public view
    returns(bool) {
        return _T.active;
    }
    
    function totalWins()
    public view
    returns(uint) {
        return _T.totalWins;
    }

    function totalGames()
    public view
    returns(uint) {
        return _T.totalGames;
    }
    
    function pending()
    public view
    returns(uint) {
        return _T.pending;
    }

    function minPrice()
    public view
    returns(uint) {
        return _T.minPrice;
    } 

    function setup() public {
        _core.setup();
    }

    function maxPrice()
    public view
    returns(uint) {
        return (address(this).balance - _T.pending) / 20;
    }
    modifier playable() {
        require(_T.active, "DAPP_DOWN");
        _T.minPrice = oraclize_getPrice("URL", _T.queryGas) * 6;
        require(msg.value >= _T.minPrice, "SEND_MOAR_ETH_TO_START_GAME");
        require(msg.value < maxPrice(), "NOT_ENOUGH_ETH_IN_POOL");
        _;
    }

    modifier onlyDev() {
        assert(msg.sender == dev);
        _;
    }

    function devToggle()
    public
    onlyDev {
        _T.active = !_T.active;
    }

    function devChangeQuery(string memory _q)
    public
    onlyDev {
        _T.queryString = _q;
    }

    function devChangeGas(uint _gas)
    public
    onlyDev {
        _T.minPrice = _gas;
    }

    function read(uint8 _a, uint8 _q, uint8 _k)
    public view
    returns(uint8) {
        return _core.read(_a, _q, _k);
    }

    function __callback(bytes32 _id, string memory random)
    public {
        require(msg.sender == oraclize_cbAddress(), "ONLY_CALLLBACK_ADDR");
        uint gameID = callback2ID[_id];
        TP.GAME storage _game = game[gameID];
        require(bytes(_game.random).length == 0, "CALLLBACK_REEE");
        _game.random = random;
        (uint8[2] memory _stat, uint8[3][2] memory _y) = _core.readStat(_id.cardGen(random));
        _T.pending -= _game.bet;
        TP.GG _result = _stat.cardCompare(_y);
        if (_game._side) {
            _result = (_result == TP.GG.WIN) ? TP.GG.LOSE : TP.GG.WIN;
            _stat[0] = _stat[1];
        }
        if (_result == TP.GG.WIN) {
            _T.totalWins++;
            uint _mooney = (_game.bet).reward(_stat[0], _T.minPrice);
            address payable addr = address(uint160(_game.player));
            emit Result(gameID, _game.player, _result, _mooney);
            addr.transfer(_mooney);
        } else {
            emit Result(gameID, _game.player, _result, _game.bet);
        }
    }

    function getCards(bytes32 _cbid, string memory _random, bool _sort)
    public view
    returns(TP.CARD[3][2] memory _card, TP.STAT[2] memory _stats) {
        (_card, _stats) = _core.getCards(_cbid, _random, _sort);
    }

    function getGameData(uint _game)
    public view
    returns(TP.GAME memory) {
        return game[_game];
    }

    function getCardsByGID(uint gameID, bool _sort)
    public view
    returns(TP.CARD[3][2] memory hands, TP.STAT[2] memory _stats) {
        TP.GAME memory _game = game[gameID];
        if (bytes(_game.random).length != 0) {
            return getCards(_game.callback, _game.random, _sort);
        }
    }

    function getCardsByCBID(bytes32 _cbid, bool _sort)
    public view
    returns(TP.CARD[3][2] memory _hands, TP.STAT[2] memory _stats) {
        TP.GAME memory _game = game[callback2ID[_cbid]];
        if (bytes(_game.random).length != 0) {
            return getCards(_cbid, _game.random, _sort);
        }
    }


    function play(bool _side)
    playable
    public payable
    returns(bytes32 _id) {
        _id = oraclize_query("URL", _T.queryString, _T.queryGas);
        callback2ID[_id] = _T.totalGames;
        TP.GAME storage _game = game[_T.totalGames];
        _game.callback = _id;
        _game._side = _side;
        _game.player = msg.sender;
        _game.bet = msg.value;
        emit NewGame(_T.totalGames, msg.sender, _side, msg.value);
        _T.totalGames++;
        _T.pending += msg.value;
    }

    function destroy() 
    public onlyDev {
        selfdestruct(msg.sender);
    }

    function defund(uint _value) 
    public onlyDev {
        (msg.sender).transfer(_value);
    }

    function () external payable {
        // Thank You
    }
}