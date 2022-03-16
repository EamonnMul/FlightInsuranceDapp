import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }
    ////////////////////////////////
    buyFlightInsurance(flightIdx, callback) {
        let self = this;

        let flight = self.flights[parseInt(flightIdx)];

        self.appContract.methods
            .buyInsurance(flight.airlineAddress, flight.flightNumber, flight.departureTime)
            .send({from: self.passengerAddress, value: self.ONE_ETHER, gas: 3000000}, (error, result) => {
                if (error) {
                    console.error(error);
                }
                callback(error, flight);
            });
    }


    withdrawFlightInsuranceCredit(flightIdx, callback) {
        let self = this;

        let flight = self.flights[parseInt(flightIdx)];


        self.appContract.methods
            .WithdrawInsurance(
                //desired amount of the balance to withdraw
            )
            .send({from: self.passengerAddress}, (error, result) => {
                if (error) {
                    console.error(error);
                }
                callback(error, flight);
            });
    }
}