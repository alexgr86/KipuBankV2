//SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
	*@title Contrato Kipu-Bank
	*@notice Contrato con fines educativos.
	*@author alexgr86
	*@custom:security No usar en producción.
*/
contract KipuBank {

	/*///////////////////////
					Variables
	///////////////////////*/
	///@notice immutable variable - global deposit limit in wei
	uint256 immutable i_bankCap;
    ///@notice immutable variable - withdrow limit in wei
	uint256 immutable i_withdrowLimit;
    ///@notice internal variable - reentrancy flag
    uint internal reentrancyFlag;
    ///@notice storage variable - deposit count
    uint256 public s_depositCount;
    ///@notice storage variable - withdrow count
    uint256 public s_withDrowCount;
	///@notice mapping varible - accounts list
	mapping(address owner => uint256 valor) public s_accounts;
	
	/*///////////////////////
						Events
	////////////////////////*/
	///@notice event - deposit done
	event Account_DepositOk(address owner, uint256 valor);
    ///@notice event - withdrow done
	event Account_WithdrowOk(address owner, uint256 valor);
    ///@notice event - hacking attact
	event Hacking_Try(address source, string message);

	
	/*///////////////////////
						Errors
	///////////////////////*/
	///@notice error - transaction fails
	error Transaction_Fails();
    ///@notice error - global bank limit
	error Transaction_GlobalLimit(address source, uint256 valor);
    ///@notice error - non-existent account
	error Transaction_AccountWithOutBalance(address source);
    ///@notice error - ammount limit
	error Transaction_DepositLimit(address source, uint256 valor);
    ///@notice error - ammount limit
	error Transaction_WithdrowLimit(address source, uint256 valor);
    ///@notice error - ammount limit
	error Transaction_InvalidAmmount(address source, uint256 valor);
    ///@notice error - insufficient balance
	error Transaction_InsufficientBalance(address source, uint256 valor);
    ///@notice error - hacking attack
	error Hacking_Attact(address source, string message);

    /*///////////////////////
					Modifiers
	///////////////////////*/
    
    /**
		*@notice modifier - reentrancyGuard
		*@dev prevent reentrancy Attack
	*/
    modifier reentrancyGuard() {
        if(reentrancyFlag != 0){
            emit Hacking_Try(msg.sender, "Reentrancy");
            revert Hacking_Attact(msg.sender, "Reentrancy");
        } 
        reentrancyFlag = 1;
        _;
        reentrancyFlag = 0;
    }

    /**
		*@notice modifier - onlyValidAmmount
		*@dev prevent Invalid ammount transactions
	*/
    modifier onlyValidAmmount(uint256 _value) {
        if (_value <= 0) revert Transaction_InvalidAmmount(msg.sender, _value);
        _;
    }

    /**
		*@notice modifier - withdrowLimit
		*@dev prevent Out of limit transactions
	*/
    modifier withdrowLimit() {
        if (msg.value > i_withdrowLimit) revert Transaction_WithdrowLimit(msg.sender, msg.value);
        _;
    }

    /**
		*@notice modifier - onlyBalanceOk
		*@dev prevent Insufficient Balance Transactions
	*/
    modifier onlyBalanceOk() {
        if (msg.value > s_accounts[msg.sender]) revert Transaction_InsufficientBalance(msg.sender, msg.value);
        _;
    }

    constructor(uint256 _bankCap, uint256 _withdrowLimit){
		i_bankCap = _bankCap;
        i_withdrowLimit = _withdrowLimit;
        s_depositCount = 0;
        s_withDrowCount = 0;
	}

	/*///////////////////////
					Functions
	///////////////////////*/
	
	///@notice función para recibir ether directamente
	receive() external payable{
        pay(address(this), msg.value);
    }

	fallback() external{}
	
	/**
		*@notice function - Deposit value to account
		*@dev perform deposit to account
	*/
	function deposit() external payable {
        pay(msg.sender, msg.value);
    }
	
	/**
		*@notice function - withdrow value to wallet
		*@param _value - withdrow value
		*@dev must revert on fail
	*/
    function withdrawValue( uint256 _value) external payable reentrancyGuard onlyValidAmmount(_value) withdrowLimit onlyBalanceOk{
        transferValue(msg.sender,_value);
    }

    /**
		*@notice function - get wallet balance
		*@dev must revert on fail
        *@return balance current account balance
	*/
    function getBalance() external view returns (uint256 balance) {
        return s_accounts[msg.sender];
    }

    /**
		*@notice function - get max bank cap
		*@dev must revert on fail
        *@return bankCap 
	*/
    function getBankCap() external view returns (uint256 bankCap) {
        return i_bankCap;
    }

    /**
		*@notice function - get withdrowLimit
		*@dev must revert on fail
        *@return withdrowLimit withdrow limit
	*/
    function getwithdrowLimit() external view returns (uint256 withdrowLimit) {
        return i_withdrowLimit;
    }

    /**
		*@notice function - pay to address
        *@param _to - address to pay
		*@param _value - withdrow value
		*@dev must revert on fail
	*/
    function pay(address _to, uint256 _value) internal {
        
        uint256 ammount = msg.value;
        uint256 currentBalance = address(this).balance;

        if (currentBalance > i_bankCap) revert Transaction_GlobalLimit(_to, _value);
        if (ammount <= 0) revert Transaction_InvalidAmmount(_to, _value);
        
        s_accounts[_to] += _value;
        s_depositCount += 1;
        emit Account_DepositOk(_to, ammount);
    }

    /**
		*@notice function - transfer value to wallet
		*@param _to - address to transfer
		*@param _value - value to transfer
		*@dev must revert on fail
	*/
    function transferValue(address _to, uint256 _value) internal {
        
        address payable to = payable(_to); 
        s_withDrowCount += 1;
        s_accounts[msg.sender] -= _value;
        
        (bool success,) = to.call{value: _value}("");
        if (!success) revert Transaction_Fails();
        
        
        emit Account_WithdrowOk(msg.sender, _value);
    }	

}
