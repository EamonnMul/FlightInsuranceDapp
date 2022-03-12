
var Test = require('../config/testConfig.js');
const { default: app } = require('../src/server/server.js');
//var BigNumber = require('bignumber.js');

contract('Oracles', async (accounts) => {

  const TEST_ORACLES_COUNT = 20;
  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    data = config.flightSuretyData;
    appCont = config.flightSuretyApp;

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
      await appCont.registerOracle({ from: accounts[a], value: fee });
      let isOracleRegistered = await appCont.checkOracleRegistered(accounts[a]);

      let result = await appCont.getMyIndexes.call({from: accounts[a]});
      
      
      console.log(`Oracle Registered: ${isOracleRegistered} ,${result[0]}, ${result[1]}, ${result[2]}`);
    }
    }
    catch(error) {
      console.log(error);
    }

    
  });

  describe('Request the flight info from the oracles', () => {

    //define the variable names needed

    let airlineFundingAmount;
    let insuranceAmount;
    let flight;
    let departureTime;
    let flightAirline;
    let passengerAddress;

    let reportedFlightStatus;

    before('Assign variables for the test',()=>{
      //assign the variables a value
      airlineFundingAmount = web3.utils.toWei('10', 'ether');
      insuranceAmount = web3.utils.toWei('1','ether');
      flight = "NH278";
      departureTime = "1609623567158";
      flightAirline = accounts[1];
      passengerAddress = accounts[2];
      reportedFlightStatus = 20;


    });


    it ('register a flight', async () => {

      let flightRegistration = await appCont.registerFlight(flight, departureTime, {from: config.flightAirline})
      console.log('flight reg ', flightRegistration);
      let checkFlightReg = await appCont.checkFlightRegistered(config.flightAirline,flight, departureTime);
      assert(checkFlightReg,true, 'Flight has not been successfully registerec')

    })

    it('Request Flight Status using fetchFlightStatus()', async () =>  {

      let result = await appCont.fetchFlightStatus(config.flightAirline,flight,departureTime);

    });

  });

  



 
});
