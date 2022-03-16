var Test = require('../config/testConfig.js');
//var BigNumber = require('bignumber.js');
const truffleAssert = require('truffle-assertions');

contract('Oracles', async (accounts) => {

  
  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    data = config.flightSuretyData;
    app = config.flightSuretyApp;
    accounts = config.testAddresses;

    accounts1 = await web3.eth.getAccounts();
    const ORACLES_COUNT = accounts1.length ;
  

    // Watch contract events
    const STATUS_CODE_UNKNOWN = 0;
    const STATUS_CODE_ON_TIME = 10;
    const STATUS_CODE_LATE_AIRLINE = 20;
    const STATUS_CODE_LATE_WEATHER = 30;
    const STATUS_CODE_LATE_TECHNICAL = 40;
    const STATUS_CODE_LATE_OTHER = 50;

  });


 

  it('can generate random indexes', async () => {

    let indexs = []

    try{
      for (let index = 0; index < accounts.length; index++) {
        let randomInt = await app.generateIndexes.call(accounts[index]);
        indexs.push(randomInt);
      }
    }
    catch(e){
      console.log(e);
    }

    assert(indexs.length,accounts.length,'Not expected')


  });

  it('Oracles are able to register', async () => {

    let regFee = web3.utils.toWei('1', 'ether');


    for(let a=1; a< accounts1.length; a++) {      
      await config.flightSuretyApp.registerOracle({ from: accounts1[a], value: regFee });
      let result = await config.flightSuretyApp.getMyIndexes.call({from: accounts1[a]});
      console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
    }
  });

 

  it('Can submit request flight status information', async () => {
     // ARRANGE
     let flight = 'ND1309'; // Course number
     let timestamp = new Date(2020, 11, 30, 18, 0, 0).valueOf().toString();
     let noError = true;  
    

     try {
       // Submit a request for oracles to get status information for a flight
     let result = await app.fetchFlightStatus(config.firstAirline, flight, timestamp);
     truffleAssert.eventEmitted(result,'OracleRequest');
    
     } catch (error) {
       noError = false;
       
     }
    
     assert(noError,true, 'unable to Submit request');

    
  });

  it('Submit an oracle response', async () => {
    let flight = 'ND1309'; // Course number
    let timestamp = new Date(2022, 11, 30, 18, 0, 0).valueOf().toString();
    let noError = true;  
    let responses= 0;
    let nonresponses = 0;
    

  

    

   
   
    let request = await app.fetchFlightStatus(config.firstAirline, flight, timestamp);
    truffleAssert.eventEmitted(request,'OracleRequest');
    
     for (let index = 1; index < accounts1.length; index++) {
       //checking Oracle Registration
       let result = await app.checkOracleRegistered(accounts1[index]);
       assert(result,true,'Oracle not registered')
       
       let OracleIndexs = await app.getMyIndexes({from: accounts1[index]})
       try {
        for (let idx = 0; idx < 3; idx++) {
          let submission = await app.submitOracleResponse(OracleIndexs[idx],config.firstAirline,flight,timestamp,timestamp,10, {from: accounts1[index]});
          responses++;}
       } catch (error) {
         
       }
       
    }
     
  

    console.log('Responses: ', responses );

  });



 
});