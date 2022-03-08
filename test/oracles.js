
var Test = require('../config/testConfig.js');
//var BigNumber = require('bignumber.js');

contract('Oracles', async (accounts) => {

  const TEST_ORACLES_COUNT = 20;
  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    data = config.flightSuretyData;
    app = config.flightSuretyApp;

    // Watch contract events
    const STATUS_CODE_UNKNOWN = 0;
    const STATUS_CODE_ON_TIME = 10;
    const STATUS_CODE_LATE_AIRLINE = 20;
    const STATUS_CODE_LATE_WEATHER = 30;
    const STATUS_CODE_LATE_TECHNICAL = 40;
    const STATUS_CODE_LATE_OTHER = 50;

  });


  it('can register oracles', async () => {
    
    // ARRANGE
    let fee = web3.utils.toWei('1', 'ether');


    

    try {
      // ACT
    for(let a=1; a<TEST_ORACLES_COUNT; a++) {     
      await app.registerOracle({ from: accounts[a], value: fee });
      let isOracleRegistered = await app.checkOracleRegistered(accounts[a]);

      let result = await app.getMyIndexes.call({from: accounts[a]});
      
      
      console.log(`Oracle Registered: ${isOracleRegistered} ,${result[0]}, ${result[1]}, ${result[2]}`);
    }
    }
    catch(error) {
      console.log(error);
    }

    
  });



 
});
