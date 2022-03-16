
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })

          // WITHDRAW CREDIT
          DOM.elid('withdraw-credit').addEventListener('click', () => {
            let flightId = parseInt(DOM.elid('flight-selection').value);

            contract.WithdrawInsurance(flightId, (error, result) => {
                display('Flight insurance', 'Withhdraw flight insurance credit', [{
                    label: 'Status',
                    error: error,
                    value: `Flight insurance credit withdrawn!`
                }]);
            });
        });

         // GET BALANCE
         DOM.elid('get-balance').addEventListener('click', () => {
            contract.getUserBalance((error, result) => {
                display('User', `passenger (Account 3: ${contract.passengerAddress})`, [{
                    label: 'Current balance',
                    error: error,
                    value: `${result} ether`
                }]);
            });
        });
    
    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}









