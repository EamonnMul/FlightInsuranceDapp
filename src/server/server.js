import { createRequire } from "module"; // Bring in the ability to create the 'require' method
const require = createRequire(import.meta.url);
const  FlightSuretyApp = require('../../build/contracts/FlightSuretyApp.json' ) ;
const  Config = require('./config.json');
const Web3 = require('web3')  ;
const express = require('express') ;

const ORACLES_COUNT = 20;
const REGISTRATION_FEE = web3.utils.toWei("1", "ether");

const FlightStatusCodeMapping = {
    STATUS_CODE_UNKNOWN: 0,
    STATUS_CODE_ON_TIME: 10,
    STATUS_CODE_LATE_AIRLINE: 20,
    STATUS_CODE_LATE_WEATHER: 30,
    STATUS_CODE_LATE_TECHNICAL: 40,
    STATUS_CODE_LATE_OTHER: 50
};

const StatusArray = [
  FlightStatusCodeMapping.STATUS_CODE_UNKNOWN, FlightStatusCodeMapping.STATUS_CODE_ON_TIME, 
  FlightStatusCodeMapping.STATUS_CODE_LATE_AIRLINE, FlightStatusCodeMapping.STATUS_CODE_LATE_WEATHER,
  FlightStatusCodeMapping.STATUS_CODE_LATE_TECHNICAL, FlightStatusCodeMapping.STATUS_CODE_LATE_OTHER
]
let OracleIndexes = {}


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

web3.eth.getAccounts().then(accounts => {
  console.log(accounts)
});


flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    console.log(event)
});

OraclesRegistration(); 

///////////////Functions/////////////////////

//Register Oracles

function OraclesRegistration() {
  for (let index = 1; index < ORACLES_COUNT; index++) {
    registerOracle(index,accounts[index]);
  }
}
function registerOracle(idx, oracleAddress) {

  flightSuretyApp.methods.registerOracle()
        .send({from: oracleAddress, value: REGISTRATION_FEE, gas: 3000000}, (error, result) => {
            if (error) throw error;
            getOracleIndexes(oracleAddress);
        });

}



//fetch the indexes of  the newly registered Oracles
function getOracleIndexes(oracleAddress) {
  flightSuretyApp.methods.getMyIndexes().call({from: oracleAddress}, (error, result) => {
      if (error) throw error;
      OracleIndexes[oracleAddress] = result;
  });
}

function generateRandomFlightStatusCode() {
  let idx = Math.floor(Math.random() * StatusArray.length); //get random result
  return StatusArray[idx];
}

function submitFlightStatusInfoFromMatchingOracles(requestedIndex, flight) {
  console.log(`Submit flight status info from matching oracles to requestedIndex=${requestedIndex}`);

  for (let i = 1; i < ORACLES_COUNT; i++) {
      let oracleAddress = accounts[i];
      let indexes = OracleIndexes[oracleAddress];
      if (indexes.includes(requestedIndex)) {
          submitFlightStatusInfo(oracleAddress, requestedIndex, flight);
      }
  }
}

function submitFlightStatusInfo(oracleAddress, requestedIndex, flight) {
  let flightStatusCode = generateRandomFlightStatusCode();
  flightSuretyApp.methods.submitOracleResponse( requestedIndex, flight.airlineAddress, flight.flightNumber, flight.departureTime,flightStatusCode)
      .send({from: oracleAddress, gas: 3000000}, (error, result) => {
          if (error) {
              console.log(error);
          } else {
              console.log(`<oracleAddress = ${oracleAddress}: successful submission of Flight Status information`);
          }
      });
}




const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


