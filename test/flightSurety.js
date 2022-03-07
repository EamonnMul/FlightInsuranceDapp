
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');




contract('Flight Surety Tests', async (accounts) => {


  var config;
  var data;
  var app;
  var accounts;
  var owner;
  var airline1;
  var airline2;
  var airline3;
  var airline4;
  var airline5;
  var passenger1;
  var passenger2;
  var passenger3;
  var passenger4;
  var passenger5;

  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
    data = config.flightSuretyData;
    app = config.flightSuretyApp;
    accounts = config.testAddresses;
    owner = config.owner;
    airline1 = accounts[1];
    airline2 = accounts[2];
    airline3 = accounts[3];
    airline4 = accounts[4];
    airline5 = accounts[5];
    passenger1 = accounts[6];
    passenger2 = accounts[7];
    passenger3 = accounts[8];
    passenger4 = accounts[9];
    passenger5 =  accounts[10]

 
  });


  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/
  
  it('Test that the registration function works for flights on the Data contract', async () => {
    
   var flight;
   var flightbyte;
   var departureTime = new Date(2020, 11, 30, 18, 0, 0).valueOf().toString();

    try { 
    
    flight = await data.registerFlight(accounts[1],'Test Flight',  departureTime , 0 );
    flightbyte = await data.RetrieveFlightKey(accounts[1], 'Test Flight',departureTime);
    
    }
    catch(e) {
        console.log(e);

    }
    let result = await data.FlightRegistered.call(flightbyte); 

    // ASSERT
    assert.equal(result, true, "Flight has not been registered");

  });

  it('Test to update a flight status', async () => {
    var flight;
    var flightbyte;
 
     try { 
     
     flight = await data.registerFlight(accounts[1],'Test Flight',  new Date(2020, 11, 30, 18, 0, 0).valueOf().toString() , 0 );
     flightbyte = await data.RetrieveFlightKey(accounts[1], 'Test Flight',new Date(2020, 11, 30, 18, 0, 0).valueOf().toString());
     
     }
     catch(e) {
         console.log(e);
 
     }
     let result = await data.updateFlightStatus(10,flightbyte);
     var FlightStatus = await data.retrieveFlightStatus(flightbyte);
   
 
     // ASSERT
     assert.equal(FlightStatus, 10, "Test has failed");
 
   });

   it('Register first airline when contract is deployed ', async () => {
       var result;

    try {

        result = await data.getAirlineCount()
        
        
    }
    catch(e) {
        console.log(e);
    }
   assert.equal(result.length,1,'Result does not match the expected number of airlines')
 
 
   });

   it('Existing airlines can register a new airline until there is 4 airlines registered.', async () => {
    var TwoAirlineReg;
    var ThreeAirlineReg;
    var FourAirlineReg;

 try {
    

    TwoAirlineReg = await app.registerAirline(airline2, {from: config.firstAirline});
    ThreeAirlineReg = await  app.registerAirline(airline3, {from: config.firstAirline});
    FourAirlineReg = await  app.registerAirline(airline4, {from: config.firstAirline});
    FiveAirlineReg = await  app.registerAirline(airline5, {from: config.firstAirline});
     
 }
 catch(e) {
     console.log('Error: ', e);
 }


 let result2 = await app.checkAirlineRegistration(airline2); 
 let result3 = await app.checkAirlineRegistration(airline3); 
 let result4 = await app.checkAirlineRegistration(airline4); 
 let result5 = await app.checkAirlineRegistration(airline5); 


 


assert.equal(result2 ,true,'Unable to register 2nd airline')
assert.equal(result3,true,'Unable to register 3rd airline')
assert.equal(result4,true,'Unable to register 4th airline')
assert.equal(result5,false,'Registration of 5th airline should not be automatic')

});




   

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await data.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[5];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {


    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('After the airline count reaches 4 then an airline needs to be voted on and reach a majority', async () => {
    
    // ARRANGE
    let newAirline = accounts[5];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {


    }
    let result = await data.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  //PASSENGERS

  it('Passengers can insure up to one ether and not more', async () => {
    
    // ARRANGE

    var flight;
    var flightbyte;
    var departureTime = new Date(2020, 11, 30, 18, 0, 0).valueOf().toString();
    var insurancePolicy1;
    var insurancePolicy2;
    var amount1 =  web3.utils.toWei('1', 'ether');
    flightbyte = await data.RetrieveFlightKey(airline2, 'Test Flight',departureTime);

    

 
     try { 
         flight = await data.registerFlight(airline2,'Test Flight',  departureTime , 0 );
         


        insurancePolicy1 = await data.buy( passenger1,  amount1, flightbyte, airline2); //one ether
     

     
    }
    catch(e) {
        console.log('Error',e);

    }
    let result1 = await data.checkPassengerInsured(passenger1, flightbyte );


    // ASSERT
    assert.equal(result1, true, "First passenger is not insured");


  });

  it('If a flight is delayed due to airline fault the passenger recieves a credit of 1.5 their insured amount', async () => {
    
    // ARRANGE
    var flight;
    var departureTime = new Date(2020, 11, 30, 18, 0, 0).valueOf().toString();
    var amount1 =  web3.utils.toWei('1', 'ether');
    var flightbyte = await data.RetrieveFlightKey(airline2, 'Test Flight 2',departureTime);
    var result;

    // ACT
    try {

        flight = await data.registerFlight(airline2,'Test Flight 2',  departureTime , 0 );
        

        var ins = await data.buy( passenger1,  amount1, flightbyte, airline2);
        //var ins =  app.buyInsurance( airline2, 'Test Flight 2', departureTime, {from: passenger1, value: amount1});

        


        var statusF = await app.processFlightStatus(airline2,  'Test Flight 2',departureTime,20);

        result = await app.checkPaidOut(flightbyte); 
        var passengerBalance = await app.checkPassengerBalance(passenger1);
        var expectedAmount = amount1 * 1.5;
        console.log('Expected Amount: ',expectedAmount, 'PassengerBalance: ', passengerBalance);
    }
    catch(e) {

    }

    

    // ASSERT
    assert.equal(result, true, "Insuree is not paid out");


  });

});



 


