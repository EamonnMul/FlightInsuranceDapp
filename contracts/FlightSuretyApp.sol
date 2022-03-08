// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;



// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;
    uint8 private constant CONSENSUS_THRESHOLD = 4;
    uint8 private constant VOTE_THRESHOLD = 2;

    uint256 public constant  MAX_AMOUNT = 1 ether; 
    uint256 public constant MIN_FUNDING = 10 ether;


    address private contractOwner;          // Account used to deploy contract

    address payable public  dataContractAddress;
    
 
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
         // Modify to call data contract's status
        require(true, "Contract is currently not operational");  
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier ContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier RegisteredAirline() {
        require(
            flightData.checkAirlineRegistration(msg.sender) == true,"Airline is not registered");
        _;
    }

    modifier FundedAirline(address airlineAddress) {
        require(
            flightData.checkAirlineFunded(airlineAddress) == true, "Airline is not funded");
        _;
    }

    modifier AirlineNominated(address airlineAddress) {
        require(
            flightData.AirlineNominated(airlineAddress) == true,
            "Airline cannot be registered"
        );
        _;
    }

    modifier AirlineNotRegistered(address airlineAddress) {
        require(
            flightData.checkAirlineRegistration(airlineAddress) == false, "Airline is already registered");
        _;
    }

    modifier NotFunded(address airlineAddress) {
        require(
            flightData.checkAirlineFunded(airlineAddress) == false, "Airline is funded"
        );
        _;
    }

    modifier FlightRegistered(address airline, string memory flight, uint256 departureTime) {
        require(flightData.FlightRegistered(keccak256(abi.encodePacked(airline, flight, departureTime))) == true, "Flight not registered");
        _;
    }

    modifier PaymentSufficient() {
        require(
            msg.value <= MAX_AMOUNT, "1 ether and no more may be sent to purchase insurance"
        );
        _;
    }

    modifier MinFunding() {
        require(msg.value >= MIN_FUNDING,"Airline funding requires at least 10 Ether");
        _;
    }

    modifier SufficientReserves(address airlineAddress, uint256 insuranceAmount) {
        uint256 amount = flightData.totalInsured(airlineAddress).add(insuranceAmount).mul(3).div(2);
        require(amount <= flightData.AirlineFunds(airlineAddress),"Insufficient reserves to provide insurance");
        _;
    }

    

        /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event NominateAirline(address indexed airlineAddress);

    

    event AirlineRegistration(address indexed airlineAddress);

    event AirlineFundingAdded(
        address indexed airlineAddress,
        uint256 amount
    );

    event RegisterFlight(address indexed airlineAddress,string flight);

    event InsuranceBought(address indexed passengerAddress, uint256 amount);

    event PayoutInsurance(address indexed airlineAddress, string flight);

    event withdrawInsurance(address indexed passengerAddress, uint256 amount);

    event FlightStatusInfo(address airline,string flight,uint256 departureTime,uint8 status);

    event OracleRequest(uint8 index,address airline,string flight,uint256 departureTime );

    event OracleReport(address airline, string flight, uint256 departureTime, uint8 status);

    event OracleRegistered(address indexed oracleAddress, uint8[3] indexes);

     /**
    * @dev Add an airline to the registration queue
    *
     
     
                            
                            
    */   
    
    function registerAirline(  address airlineAddress) 

                            external
                            AirlineNotRegistered(airlineAddress)
                            requireIsOperational() 
                            FundedAirline(msg.sender)
                            
                        
                            
                            returns (bool)
                            
                            
    {
         {
        uint256 votes = flightData.AirlineVote(airlineAddress, msg.sender);
        bool result;
        if (flightData.getAirlineCount() > CONSENSUS_THRESHOLD) {
            if (votes >= flightData.getAirlineCount().div(VOTE_THRESHOLD)) { //checking if there is over half the amount of airlines in votes to register
                result = flightData.registerAirline(airlineAddress);
                emit AirlineRegistration(airlineAddress);
            } else {
                result = false; 
            }
        } else {
            require(flightData.checkAirlineRegistration(msg.sender),'Airline must be registered by exiting member');
            flightData.nominateAirline(airlineAddress);
            result = flightData.registerAirline(airlineAddress);
            emit AirlineRegistration(airlineAddress);
        }
        return result; 
    }
    }

    function checkAirlineRegistration( address air) public  view returns(bool) {
        return flightData.checkAirlineRegistration(air);
    }

     function checkOracleRegistered(address oracleAddress) public view requireIsOperational returns (bool)
    {
        return oracles[oracleAddress].isRegistered;
    }

    function checkPassengerInsured(address passenger,address airline,string memory flight,uint256 departureTime
    ) external view requireIsOperational returns (bool) {
        bytes32 key = getFlightKey(airline, flight, departureTime);
        return flightData.checkPassengerInsured(passenger, key);
    }

    function checkPaidOut(bytes32 flightKey) external view requireIsOperational returns(bool)
    {
        return flightData.checkPaidOut(flightKey);
    }

    function checkPassengerBalance(address passengerAddress) external view requireIsOperational returns (uint256)
    {
        return flightData.checkPassengerBalance(passengerAddress);
    }




  
    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() 
                            public 
                            view
                            returns(bool) 
    {
        return flightData.isOperational();  // Modify to call data contract's status
    }

     

    function setOperationalStatus(bool mode) external ContractOwner returns (bool)
    { return flightData.setOperatingStatus(mode);}

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/
     
    function WithdrawInsurance(uint256 amount) external requireIsOperational{
        flightData.pay(payable(msg.sender), amount);
        emit withdrawInsurance(msg.sender, amount);}

     function buyInsurance( address airline, string memory flight, uint256 departureTime) external payable requireIsOperational PaymentSufficient() SufficientReserves(airline, msg.value)
    {
        bytes32 key = getFlightKey(airline, flight, departureTime);
        flightData.buy(msg.sender, msg.value, key, airline);
        dataContractAddress.transfer(msg.value);
        emit InsuranceBought(msg.sender, msg.value);
    }



  
  


   
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 departureTime,
                                    uint8 statusCode
                                )
                                public
    {
        bytes32 flightKey = getFlightKey(airline, flight, departureTime);
        flightData.updateStatusOfFlight(statusCode, flightKey);
        if (statusCode == STATUS_CODE_LATE_AIRLINE) {
            flightData.creditInsurees(flightKey, airline);
            emit PayoutInsurance(airline, flight);
        }
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp                            
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        ResponseInfo storage newResponse = oracleResponses[key];
        newResponse.requester= msg.sender;
        newResponse.isOpen = true;
        emit OracleRequest(index, airline, flight, timestamp);
    } 

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

//Function to fund airline

 function fundAirline()
        external
        payable
        requireIsOperational
        MinFunding
    {
        dataContractAddress.transfer(msg.value);
        flightData.fundAirline(msg.sender, msg.value);
        emit AirlineFundingAdded(msg.sender, msg.value);
    }

//function to nominate an airline

function nominateAirline(address airlineAddress) external requireIsOperational
{ flightData.nominateAirline(airlineAddress);
        emit NominateAirline(airlineAddress);}

function registerFlight(string memory flight, uint256 departureTime 
    ) external requireIsOperational {
        flightData.registerFlight(
            msg.sender,
            flight,
            departureTime,
            STATUS_CODE_UNKNOWN
        );
        emit RegisterFlight(msg.sender, flight);
    }



// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

  
    


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");
        uint8[3] memory indexes = generateIndexes(msg.sender);
        oracles[msg.sender] = Oracle({ isRegistered: true,indexes: indexes});
        emit OracleRegistered(msg.sender, indexes);

    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string memory flight,
                            uint256 timestamp,
                            uint256 departureTime,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight,  departureTime, statusCode);
        }
    }


    

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

       indexes[2] = indexes[1];
       while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
       }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

receive() external payable {
        // custom function code
    }

/********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */

    FlightSuretyData private flightData;

    constructor
                                (
                                    address payable DataContract, address firstAirline
                                ) 
                                 
    {
        
        contractOwner = msg.sender;
        dataContractAddress = DataContract;
        flightData = FlightSuretyData(DataContract);
        flightData.nominateAirline(firstAirline);
        flightData.registerAirline(firstAirline);
        flightData.fundAirline(firstAirline,10000000000000000000);
    }


}   

  
