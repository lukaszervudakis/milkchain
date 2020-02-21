pragma solidity ^0.6.3;
contract Milkchain {
/*
**********1. Basic Setup*********
*/
	address admin;
	address certificator;
	address input;
	uint serialNo = 1000;
	uint serialNoFarmer = 1000;
	
	//create all necessary mappings
	mapping (address => Farmer) farmers;
	mapping (uint => Chargedairy) chargesdairy;
    mapping (address => Dairy) dairies;
	mapping (address => LSP) lsps;
	mapping (address => Certificator) certifications;
	mapping (address => Sensor) sensoren;
	mapping (uint => Request) requests;
	mapping (address => uint) balances;
	mapping (address => uint) totalShipped; //total number of shipments made*************************
	mapping (address => uint) successShipped; //number of shipments successfully completed
	
	//definition of Events to communicate feedback on blockchain. E.g. return generated serial number
	event ReturnSerialNumber(uint SerialNumber);
	event Success(string text); //events are for demonstration purposes
	event Failure(string text);
	
	//constructer - runs once when contract is deployed. Setup of admin account for supermarket
	constructor () public {
		admin = msg.sender; //could we use admin = owner instead?
	    balances[admin] = 1000; // create a token balance for the start.
	}
	
	//create structs
	//producer = farmer
	struct Farmer {
		string name;
		string town;
		string mail;
		uint certified; //for bio certification
	}
	//dairy
	 struct Dairy {
	    string name;
	    string town;
	    string mail;
	 }
	 //logisticsserviceprovider
	 struct LSP {
    	 string name;
    	 string town;
    	 string mail;
	 }
	 //bio certification agency
	 struct Certificator {
    	 string name;
    	 string town;
    	 string mail;
	 }
	 //all infos of each shipment
	struct Chargefarmer {
		address farmer; //address of the farmer
		address sensor; //address of the respective sensor which generates the data
        uint quantity; //quantity of the shipment
		uint[] locationData;
		uint timeStampCreation; //timestamp of the creation date of the shipment
		uint timeStampDairy; //timestamp of when the dairy has received the shipment
	    bool approvaldairy; //Used to check the charge by the dairy. if negative, the charge will not be further processed
	}
	
	struct Chargedairy {
	    mapping (uint => Chargefarmer) chargesfarmer;
	    uint[] listofSerialNoFarmer; //List of all Farmers in mapping
	    address dairy; //address of the dairy 
	    address sensor; //address of the new sensor
	    address lsp; //address of the logistics service provider (lsp)
		bool approvalsupermarket;
		bool approvallsp;
		uint[] locationData; //currently not used
		uint timeStampLSP; //timestamp of when the lsp has received the shipment
		uint timeStampSupermarket; //timestamp of when the supermarket has received the shipment
		uint timeStampDairyProduction; //timestamp of when the Dairy finished production
		uint quantity; //total quantity after mixing multiple charges from Farmers
	
	}
	
	struct Sensor {
	    int highestTemp; //highest temperature measured by the sensor
	    int lowestTemp; //lowest temperature measured by the sensor
	    int highestPH; //highest PH measured by the sensor
	    int lowestPH; //lowest PH measured by the sensor
	    uint timeStamp; //timestamp of measurement
	}
	
  
	struct Request {
	    address farmer; //address of the producer to which a request is made by the dairy
	    address dairy; //address of the dairy to which a request is made by the supermarket
	    uint requestedquantity; //requested quantity from dairy by supermarket
	    uint requestedquantityfromFarmer; //requested quantity from farmer by dairy
	    uint payment; //amount of payment in token
	}
	
	//modifiers to restrict access of functions.
	modifier onlyAdmin() {
	    require(msg.sender == admin, "You have no permission"); //admin = owner = supermarket
		_;
	}
	
	modifier onlyCertificator () {
	    require(msg.sender == certificator, "You are not the Certificator"); //bio certification agency only
		_;
	}
	
	modifier onlyDairy () { //**************************
	    require(bytes(dairies[msg.sender].name).length != 0, "Your account is not registered as dairy"); //Modifier function to restrict access to dairies
	    _;
	}
	modifier onlyFarmer () { //**************************
	   require(bytes(farmers[msg.sender].name).length != 0, "Your account is not registered as Farmer"); //Modifier function to restrict access to farmers
	    _;
	}
	
	modifier onlyLSP () { //**************************
	   require(bytes(lsps[msg.sender].name).length != 0, "Your account is not registered as LSP"); //Modifier function to restrict access to LSPs
	    _;
	}

/*
**********2. Functions for Setup***************
*/

	//Function to add farmer. Access only for admin and dairy
	function D_addFarmer(address _address, string memory _name, string memory _town, string memory _mail) onlyDairy public returns (bool success) {
		//check if farmer exists already and if input is not empty
		if (bytes(farmers[_address].name).length == 0 && bytes(_name).length != 0) {
			farmers[_address].name = _name; //adds basic info of farmer
			farmers[_address].town = _town;
			farmers[_address].mail = _mail;		
			return true;
		}
		
		else {
			//**************************
			return false; //return if criteria is not met
		}
	}
	
	//function to add dairy, restricted to supermarket
    function C_addDairy(address _address, string memory _name, string memory _town, string memory _mail) onlyAdmin public {
		//check if dairy exists already and if input is not empty
		require (bytes(dairies[_address].name).length == 0, "Dairy already existing"); //Validates if dairy is already created. Checks could be enhanced --> "no input, invalid name" etc.
			dairies[_address].name = _name; //adds basic info 
			dairies[_address].town = _town;
			dairies[_address].mail = _mail;
		    balances[_address] = 1000;
	}
	
	//function to add LSP
	function B_addSpedition(address _address, string memory _name, string memory _town, string memory _mail) onlyAdmin public {
			//check if LSP exists already and if input is not empty
			require (bytes(farmers[_address].name).length == 0 );
				lsps[_address].name = _name; //add basic info
				lsps[_address].town = _town;
				lsps[_address].mail = _mail;		
	}
	
	function A_addCertificator (address _address, string memory _name, string memory _town, string memory _mail) onlyAdmin public {
			certificator = _address;
			//check if certification agency exists already and if input is not empty
			require (bytes(certifications[_address].name).length == 0);
				certifications[_address].name = _name; //add basic info
				certifications[_address].town = _town;
				certifications[_address].mail = _mail;		
	}	
	
		//Function to certify farmers, restricted to certificator
	function E_certifyFarmer(address _farmer) onlyCertificator public returns (bool succcess) {
		farmers[_farmer].certified = block.timestamp; //changes certification status of selected farmer to true
		//posibility to limit it to a certain timeframe could be added
		return true;
	}
	
/*
********* 3. Find and Remove Functions *********
*/

	//remove functions of accounts, restricted to admin
	
	function X_removeDairy(address _dairy) onlyAdmin public returns (bool success) {
			delete dairies[_dairy];
			return true;
	}	

	function X_removeLSP(address _spedition) onlyAdmin public returns (bool success) {
			delete lsps[_spedition];
			return true;
	}

	function X_removeFarmer(address _farmer) onlyDairy public returns (bool success) {
		delete farmers[_farmer];
		return true;
	}
	
	function X_removeCertificator(address _certificator) onlyAdmin public returns (bool success) {
		delete certifications[_certificator];
		return true;
	}
	
	//find functions to display detailed info of each account
	
	//Function to display account balance of tokens. Could be restricted to e.g. onlyAdmin
	function X_getBalance(address _account) public view returns (uint _balance) {
        return balances[_account];
    }

	function X_findFarmer(address _farmer) view public returns (string memory, string memory, string memory, uint) {
		return (farmers[_farmer].name, farmers[_farmer].town, farmers[_farmer].mail, farmers[_farmer].certified);
	}
	
	function X_findDairy(address _dairy) view public returns (string memory, string memory, string memory) {
		return (dairies[_dairy].name, dairies[_dairy].town, dairies[_dairy].mail);
	}
	
	function X_findLSP(address _LSP) view public returns (string memory, string memory, string memory) {
		return (lsps[_LSP].name, lsps[_LSP].town, lsps[_LSP].mail);
	}	
	function X_findCertificator(address _certificator) view public returns (string memory, string memory, string memory) {
		return (certifications[_certificator].name, certifications[_certificator].town, certifications[_certificator].mail);
	}
	

	//function to remove certification, restricted to certificator
	function X_uncertifyFarmer(address _farmer) onlyCertificator public returns (bool succcess) {
		delete farmers[_farmer].certified; 
		return true;
	}
	
	//function to remove a charge, restricted to supermarket.
	function X_removeCharge(uint _serialNo) onlyAdmin public returns (bool success) {
		delete chargesdairy[_serialNo];
		return true;
	}

	//function to display details of a certain charge. Split in 3 different functions as max. stack deepness is 7. Alternative solution with Array possible.
	function X_findChargeAdressesandSerialNoFarmers (uint _serialNo) view public returns (address, address, address, uint[] memory) { //,uint entfernt
		return (chargesdairy[_serialNo].dairy, chargesdairy[_serialNo].sensor, chargesdairy[_serialNo].lsp, chargesdairy[_serialNo].listofSerialNoFarmer); 
	}
	
	function X_findkChargeofFarmer (uint _serialNoFarmer, uint _serialNo) view public returns (address, uint, uint, uint, bool){
	    return (chargesdairy[_serialNo].chargesfarmer[_serialNoFarmer].sensor, chargesdairy[_serialNo].chargesfarmer[_serialNoFarmer].quantity,chargesdairy[_serialNo].chargesfarmer[_serialNoFarmer].timeStampCreation, chargesdairy[_serialNo].chargesfarmer[_serialNoFarmer].timeStampDairy, chargesdairy[_serialNo].chargesfarmer[_serialNoFarmer].approvaldairy);
	    
	}
		
	function X_findChargeApprovals(uint _serialNo) view public returns (bool, bool) { //,uint entfernt
		return (chargesdairy[_serialNo].approvalsupermarket, chargesdairy[_serialNo].approvallsp); 
	}
	
	
	function X_findChargeDetails(uint _serialNo) view public returns (uint, uint, uint [] memory, uint, uint) { //,uint entfernt
		return (chargesdairy[_serialNo].quantity, chargesdairy[_serialNo].timeStampDairyProduction, chargesdairy[_serialNo].locationData, chargesdairy[_serialNo].timeStampLSP, chargesdairy[_serialNo].timeStampSupermarket); 
	}
	
    /*
	*/
/*
************* 4. Actual Functionality *********
*/
	
	//function to get the data of the sensor. could be triggered continously by a sensor connected to the blockchain in a defined timeframe, e.g. every 10 min.	
	//currently only the highest Temp is stored. 
	function X_getSensordata (int _highestTemp) public { //(, int _lowestTemp, int _highestPH, int _lowestPH)
        //if function deactivated due to demonstration purpose
        //if (_highestTemp > sensoren[msg.sender].highestTemp) {
	    sensoren[msg.sender].highestTemp = _highestTemp; //for demonstration, highesttemp is in reality current temperature. normally, 
	    //}
	    
	    /* Deactivated, as our raspberry demo only transmits one temperature value and no pH.
	    if (_lowestTemp > sensoren[msg.sender].lowestTemp) {
	    sensoren[msg.sender].lowestTemp = _lowestTemp;
	    }
	    if (_highestPH > sensoren[msg.sender].highestPH) {
	    sensoren[msg.sender].highestPH = _highestPH;
	    }
	    if (_lowestPH > sensoren[msg.sender].lowestPH) {
	    sensoren[msg.sender].lowestPH = _lowestPH;
	    } */
	    sensoren[msg.sender].timeStamp = block.timestamp; //time stamp of latest refresh 
	}
	
    //Base function to send Tokens
	function Z_sendToken(address _from, address _to, uint _amount) public {
		//check if account balance of tokens is high enough
		require (balances[_from] > _amount, "Not enough Tokens to send payment"); 
		//actual sending of tokens, add and remove from respective accounts
		balances[_from] -= _amount;
		balances[_to] += _amount;
	}
	
    //Order request by Supermarket. Currently proposed payment is added manually. Potential with Oracle to take current price of Milk for fair pricing
	function F_RequestbySupermarket (address _addressDairy, uint _requestedquantity, uint _payment) onlyAdmin public returns (uint) {
	    serialNo = serialNo +10; //increasing value of serialNo for uniqueness
	    requests[serialNo].dairy = _addressDairy; //address of the dairy from which delivery is requested
	    requests[serialNo].requestedquantity = _requestedquantity; //requested quantity
	    requests[serialNo].payment = _payment; //payment offered by the supermarket
	    emit ReturnSerialNumber(serialNo);
	    return (serialNo);
	     //serialNo is returned to Supermarket, as it triggered the function. Direct Message not Possible --> Use oracle to trigger e.g. Email or store Serial Number in Smart Contract
	    // --> https://ethereum.stackexchange.com/questions/29532/how-to-send-data-to-another-address-on-the-blockchain
	}
	
	//function to request a shipment from the farmer by dairy. Used to check if charge is correct and for payment. SerialNo is added manually, as multiple requests by supermarket to one dairy are possible
	function G_RequestbyDairy (address _addressFarmer, uint _requestedquantityfromFarmer, uint _payment) onlyDairy public returns (uint) { //funktion nur für Molkerei
	    serialNo = serialNo +10;
	    serialNoFarmer = serialNo;
	    requests[serialNoFarmer].farmer = _addressFarmer; //address of the farmer.
	    requests[serialNoFarmer].requestedquantityfromFarmer = _requestedquantityfromFarmer; //requested quantity
	    requests[serialNoFarmer].payment = _payment; //payment offered by the dairy
	    emit ReturnSerialNumber(serialNoFarmer);
	    return (serialNoFarmer);
	    //serialNo is returned to Supermarket, as it triggered the function. Direct Message not Possible --> Use oracle to trigger e.g. Email or store Serial Number in Smart Contract
	    // --> https://ethereum.stackexchange.com/questions/29532/how-to-send-data-to-another-address-on-the-blockchain
	   
	}
	

	//Function to add a charge, triggered by Farmer
	function H_addCharge(uint _serialNoFarmer, address _sensoraddress, uint _quantity) onlyFarmer public returns (bool success) {
	//requires farmer to have a valid certification (max 1 year)
	uint diff = (block.timestamp - farmers[msg.sender].certified) / 60 / 60 / 24; 
	require (diff < 365);
		//check for unique serialNo missing
				//add farmer, sensor, quantity and timestamp of charge.
    			chargesdairy[serialNo].chargesfarmer[_serialNoFarmer].farmer = msg.sender;
    			chargesdairy[serialNo].chargesfarmer[_serialNoFarmer].sensor = _sensoraddress; //use of multiple sensors, as each farmer uses one. Would merge to one sensor at dairy
    			chargesdairy[serialNo].chargesfarmer[_serialNoFarmer].quantity = _quantity;
    			chargesdairy[serialNo].chargesfarmer[_serialNoFarmer].timeStampCreation = block.timestamp;
    			return true;
    }

	//add function to display requests
	//function to hand over ownership from farmer to the dairy

	function I_approvalbyDairy (uint _serialNoFarmer, uint _serialNo) onlyDairy public {
		  	//check if temp values are good. Option for pH values:  && sensoren[charges[_serialNo].sensor].highestPH < 7 && sensoren[charges[_serialNo].sensor].lowestPH > 6.4
			//possibility to add multiple requirements of sensor data
			//usage of if / else for demonstration purpose. normally use of "require" as in the following approval functions
			if (sensoren[chargesdairy[serialNo].chargesfarmer[_serialNoFarmer].sensor].highestTemp < 9) { ////Check if min max values are respected. For more options e.g.:  && sensoren[charges[_serialNo].sensor].highestPH < 7 && sensoren[charges[_serialNo].sensor].lowestPH > 6.4
		    	chargesdairy[_serialNo].dairy = msg.sender;
				chargesdairy[_serialNo].chargesfarmer[_serialNoFarmer].timeStampDairy = block.timestamp;
				Z_sendToken (msg.sender, chargesdairy[_serialNo].chargesfarmer[_serialNoFarmer].farmer, requests[_serialNoFarmer].payment); //direct payment function. Send promised payment from dairy to farmer
	            chargesdairy[_serialNo].chargesfarmer[_serialNoFarmer].approvaldairy = true;
	            chargesdairy[_serialNo].listofSerialNoFarmer.push(_serialNoFarmer);
	         emit Success('Success Temperature is good');   
			}
			else {
			    emit Failure('Temperature is too high');
			}
	}
	
	function J_finishProductionbyDairy (address _newSensor, uint _serialNo) onlyDairy public {
	    //function to calculate total Quantity of charge. Could consist of multiple charges of farmers, therefore they need to be added.
	    uint sum_ = 0;
        for (uint i = 0; i < chargesdairy[_serialNo].listofSerialNoFarmer.length; i++) {
            sum_ += chargesdairy[_serialNo].listofSerialNoFarmer[i];
        }
	    chargesdairy[_serialNo].sensor = _newSensor; //old sensors are replaced by new one for the total charge
	    chargesdairy[_serialNo].quantity = sum_; //total quantity stored
	    chargesdairy[_serialNo].timeStampDairyProduction = block.timestamp;
	}
	

	function K_approvalbyLSP (uint _serialNo) onlyLSP public {
		    	require (sensoren[chargesdairy[_serialNo].sensor].highestTemp < 9); 
		    	chargesdairy[_serialNo].lsp = msg.sender;
				chargesdairy[_serialNo].timeStampLSP = block.timestamp;
				chargesdairy[_serialNo].approvallsp = true;
	
	}
	
	function L_approvalbySupermarket (uint _serialNo) onlyAdmin public {
				require (sensoren[chargesdairy[_serialNo].sensor].highestTemp < 9); //Check if min max values are respected. 
        	  	chargesdairy[_serialNo].dairy = msg.sender;
				chargesdairy[_serialNo].timeStampSupermarket = block.timestamp;
				Z_sendToken (msg.sender, chargesdairy[_serialNo].dairy, requests[_serialNo].payment); //payment from Supermarket to Dairy
				Z_sendToken (msg.sender, chargesdairy[_serialNo].lsp, 10); //payment from Supermarket to LSP. Currently fixed value, can be changed / calculated with quantity and distance
                chargesdairy[_serialNo].approvalsupermarket = true;
	}	
}
