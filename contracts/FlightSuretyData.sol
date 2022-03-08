// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
  

    enum AirlineStatus {None, Nominated, Registered, Funded}
    
    AirlineStatus constant StatusDefault = AirlineStatus.None;


     struct Airline {
        AirlineStatus status;
        address[] votes;
        uint256 funds;
        uint256 underwrittenAmount;
    }
    
    struct FlightInsurance {
        mapping(address => uint256) purchasedAmount;
        address[] passengers;
        bool isPaidOut;
    }

    struct Flight {
        bool isRegistered;
        address airline;
        string flight;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        
    }
    mapping(bytes32 => Flight) private flights;
    mapping(address => Airline) private airlines;
    mapping(bytes32 => FlightInsurance) private flightInsurance;
    mapping(address => uint256) private passengerBalance;
    mapping(address => bool) private authorizedCallers;
    

    uint256 public AirlineCount = 0;







    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() {
        contractOwner = msg.sender;   
    }

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
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

     
    modifier requireBalanceSufficient(address account, uint256 amount) {
        require(amount<=passengerBalance[account], "Passenger balance is less than the requested withdrawal amount");
        _;
    }

    modifier notPaidOut(bytes32 flightKey) {
        require(!flightInsurance[flightKey].isPaidOut,"This policy has already paid out");
        _;
    }
   

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
     
    function isAirline(address airline) public view returns(bool) {
        bool result = false; 
        if (airlines[airline].status != AirlineStatus.None) {
            result = true;
        }
        return result; 
    }

    function checkPassengerInsured(address passengerAddress, bytes32 flightKey) 
        external view  requireIsOperational
        returns(bool)
    {
        return flightInsurance[flightKey].purchasedAmount[passengerAddress] > 0;
    }

     function checkPaidOut(bytes32 flightKey) external view requireIsOperational returns(bool)
    {
        return flightInsurance[flightKey].isPaidOut;
    }
    function checkPassengerBalance(address passengerAddress) external view
        requireIsOperational
        returns(uint256)
    {
        return passengerBalance[passengerAddress];
    }

    function checkAirlineStatus(address airline) public view returns(AirlineStatus) {
        return airlines[airline].status; 
    }

    function checkAirlineRegistration(address airlineAddress) external view requireIsOperational returns (bool){
        return airlines[airlineAddress].status == AirlineStatus.Registered ;
    }

    function checkAirlineFunded(address airlineAddress) external view requireIsOperational returns (bool)
    {
        return airlines[airlineAddress].status == AirlineStatus.Funded;
    }

    function AirlineNominated(address airlineAddress) external view requireIsOperational returns (bool)
    {
        return airlines[airlineAddress].status == AirlineStatus.Nominated || airlines[airlineAddress].status == AirlineStatus.Registered || airlines[airlineAddress].status == AirlineStatus.Funded;
    }

    function FlightRegistered(bytes32 flightKey) external view requireIsOperational returns (bool) {
        return flights[flightKey].isRegistered;
    }

      function authorizeCaller(address _address) external requireIsOperational requireContractOwner
    {
        authorizedCallers[_address] = true;
    }

     function RetrieveFlightKey(address airline, string memory flight,uint256 departureTime
    ) public  pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, departureTime));
    }


    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool status) external requireContractOwner returns (bool)
    {
        operational = status;
        return status;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/
   // function to vote airline 
   function AirlineVote(address airlineAddress, address voterAddress)
        external
        requireIsOperational
        returns (uint256)
    {
        airlines[airlineAddress].votes.push(voterAddress);
        return airlines[airlineAddress].votes.length;
    }

    

    function getAirlineCount() public view requireIsOperational returns(uint256){
        return AirlineCount; 

    }

    /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight (address airline, string memory flight, uint256 departureTime, uint8 statusCode) external requireIsOperational returns(bool){
        bytes32 key = getFlightKey(airline, flight, departureTime);
        flights[key] = Flight( true,airline,flight, statusCode, departureTime );
        return true;}

    function totalInsured(address airlineAddress) external view requireIsOperational returns(uint256)
    {
        return airlines[airlineAddress].underwrittenAmount;
    }

     function AirlineFunds(address airlineAddress) external view requireIsOperational returns (uint256)
    {
        return airlines[airlineAddress].funds;
    }

    

    function AirlineFund(address airlineAddress, uint256 fundingAmount)
        payable 
        public
        
        requireIsOperational
        returns (uint256)
    {
        airlines[airlineAddress].funds = airlines[airlineAddress].funds.add(fundingAmount);
        airlines[airlineAddress].status = AirlineStatus.Funded;
        return airlines[airlineAddress].funds;
    }






   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline(address Address) public payable requireIsOperational returns (bool)
    {
        
        airlines[Address].status = AirlineStatus.Registered;
        AirlineCount++;
        return airlines[Address].status == AirlineStatus.Registered;
    }


    //function to nominate an Airline

     function nominateAirline(address airlineAddress) external requireIsOperational{
        airlines[airlineAddress] = Airline( AirlineStatus.Nominated, new address[](0),0,0 ); }

    //fund airline
    function fundAirline(address airlineAddress, uint256 fundingAmount) external requireIsOperational returns (uint256)
    {
        airlines[airlineAddress].funds = airlines[airlineAddress].funds.add(fundingAmount);
        airlines[airlineAddress].status = AirlineStatus.Funded;
        return airlines[airlineAddress].funds;
    }

    // function to update Flight Status 

    function updateFlightStatus(uint8 statusCode, bytes32 flightKey) external requireIsOperational  {
        flights[flightKey].statusCode = statusCode;
    }

    function retrieveFlightStatus(bytes32 flightKey) external view requireIsOperational  returns (uint8) {
        return flights[flightKey].statusCode;
    }



   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (   
                                address passengerAddress, uint256 insuranceAmount, bytes32 flightKey, address airlineAddress                          
                            )
                            external
                            payable
                            
    {
    require( insuranceAmount<= 1 ether, 'Insurance cannot exceed 1 ether');
        airlines[airlineAddress].underwrittenAmount.add(insuranceAmount);
        flightInsurance[flightKey].purchasedAmount[passengerAddress] = insuranceAmount;
        flightInsurance[flightKey].passengers.push(passengerAddress);

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                bytes32 flightKey, 
                                address airlineAddress
                                )
                                external
                                requireIsOperational
                                notPaidOut(flightKey)
    {
        for(uint i = 0; i < flightInsurance[flightKey].passengers.length; i++) {
            address Address = flightInsurance[flightKey].passengers[i];
            uint256 purchasedAmount = flightInsurance[flightKey].purchasedAmount[Address];
            uint256 payAmount = purchasedAmount.mul(3).div(2); // in order to get 1.5 
            passengerBalance[Address] = passengerBalance[Address].add(payAmount);
            airlines[airlineAddress].funds.sub(payAmount);
        }
        flightInsurance[flightKey].isPaidOut = true;
    }

     function updateStatusOfFlight(
        uint8 statusCode,
        bytes32 flightKey
    ) external requireIsOperational {
        flights[flightKey].statusCode = statusCode;
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address payable person, uint256 amount
                            )
                            external
                            requireIsOperational
    {
        passengerBalance[person] = passengerBalance[person].sub(amount);
        person.transfer(amount);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
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

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    fallback() 
                            external 
                            payable 
                            
    {
        fund();
    }

    receive() external payable {
        // custom function code
    }


}

