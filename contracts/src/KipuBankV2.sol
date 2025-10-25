//SPDX-License-Identifier: MIT
pragma solidity 0.8.30;


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IOracle} from "./IOracle.sol";

/**
	*@title Contrato Kipu-Bank
	*@notice Contrato con fines educativos.
	*@author alexgr86
	*@custom:security No usar en producción.
*/
contract KipuBankV2 is Pausable, Ownable{

    struct Balances {
        uint256 eth;
        uint256 arss;
        uint256 total;
    }

	/*///////////////////////
					Variables
	///////////////////////*/
	///@notice immutable variable - global deposit limit in wei
	uint256 immutable i_bankCap;
    ///@notice immutable variable - oracle to get price to ARSS
    IOracle immutable i_Oracle;
    ///@notice immutable variable - interface to call stable ARS token
    IERC20 immutable i_ARSS;
    ///@notice immutable variable - withdrow limit in wei
	uint256 immutable i_withdrowLimit;
    ///@notice internal variable - reentrancy flag
    uint internal reentrancyFlag;
    ///@notice storage variable - deposit count
    uint256 public s_depositCount;
    ///@notice storage variable - withdrow count
    uint256 public s_withDrowCount;
    ///@notice storage variable - current contract balance (arss+eth)
    uint256 public s_contractBalance;
	///@notice mapping varible - accounts list
	mapping(address => Balances) public s_accounts;
	
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
        if (msg.value > s_accounts[msg.sender].eth) revert Transaction_InsufficientBalance(msg.sender, msg.value);
        _;
    }

    constructor(address initialOwner, uint256 _bankCap, uint256 _withdrowLimit, IOracle _oracle, IERC20 _arss) Ownable(initialOwner){
		i_bankCap = _bankCap;
        i_withdrowLimit = _withdrowLimit;
        i_ARSS = _arss;
        i_Oracle = _oracle;
        s_depositCount = 0;
        s_withDrowCount = 0;
	}

	/*///////////////////////
					Functions
	///////////////////////*/
	
    ///@notice function to pause contract
    function pause() public onlyOwner {
        _pause();
    }

    ///@notice function to unpause contract
    function unpause() public onlyOwner {
        _unpause();
    }
    
	///@notice function to receive eth
	receive() external payable{
        _payEth(address(this), msg.value);
    }

	fallback() external{}
	
	/**
		*@notice function - Deposit value to account
		*@dev perform deposit to account
	*/
	function depositEth() external payable {
        _payEth(msg.sender, msg.value);
    }
	
	/**
		*@notice function - withdrow value to wallet
		*@param _value - withdrow value
		*@dev must revert on fail
	*/
    function withdrawEth( uint256 _value) external payable reentrancyGuard withdrowLimit onlyBalanceOk{
        _transferEth(msg.sender,_value);
    }


    /**
		*@notice function - Deposit Arss to account
        *@param _value - deposit Arss value
		*@dev perform deposit to account
	*/
	function depositArss(uint256 _value) external {
        _payArss(msg.sender, _value);
    }
	
	/**
		*@notice function - withdrow Arss to wallet
		*@param _value - withdrow Arss value
		*@dev must revert on fail
	*/
    function withdrawArss( uint256 _value) external payable reentrancyGuard withdrowLimit onlyBalanceOk{
        _transferArss(msg.sender,_value);
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
		*@notice function - pay eth to address
        *@param _to - address to pay
		*@param _value - withdrow value
		*@dev must revert on fail
	*/
    function _payEth(address _to, uint256 _value) internal {
        uint256 contractBalance = s_contractBalance + _value;
        if (contractBalance > i_bankCap) revert Transaction_GlobalLimit(_to, _value);
        
        s_accounts[_to].eth += _value;
        s_accounts[_to].total += _value;
        s_contractBalance += _value;
        s_depositCount += 1;
        emit Account_DepositOk(_to, _value);
    }

    /**
		*@notice function - transfer eth value to wallet
		*@param _to - address to transfer
		*@param _value - value to transfer
		*@dev must revert on fail
	*/
    function _transferEth(address _to, uint256 _value) internal {
        
        address payable to = payable(_to); 
        s_withDrowCount += 1;
        s_accounts[msg.sender].eth -= _value;
        s_accounts[msg.sender].total -= _value;
        s_contractBalance -= _value;
        
        (bool success,) = to.call{value: _value}("");
        if (!success) revert Transaction_Fails();
        
        
        emit Account_WithdrowOk(msg.sender, _value);
    }	

    /**
		*@notice function - pay arss to address
        *@param _to - address to pay
		*@param _value - withdrow value
		*@dev must revert on fail
	*/
    function _payArss(address _to, uint256 _value) internal { 
        uint256 arss_inEth = ((_value)*uint256(_getARSSPrice()));
        uint256 contractBalance = s_contractBalance + _value;   //Convertir a eth el value
        if (contractBalance > i_bankCap) revert Transaction_GlobalLimit(_to, _value);

        i_ARSS.transferFrom(msg.sender, address(this), _value);
        s_accounts[_to].arss += _value;
        s_accounts[_to].total += arss_inEth;    //Convertir a eth
        s_contractBalance += arss_inEth;        //Convertir a eth
        s_depositCount += 1;

        emit Account_DepositOk(_to, _value);
    }

    /**
		*@notice function - transfer ars value to wallet
		*@param _to - address to transfer
		*@param _value - value to transfer
		*@dev must revert on fail
	*/
    function _transferArss(address _to, uint256 _value) internal {
        uint256 arss_inEth = ((_value)*uint256(_getARSSPrice()));
        i_ARSS.transferFrom(address(this), msg.sender, _value);
        s_accounts[_to].arss -= _value;
        s_accounts[_to].total -= arss_inEth;    //Convertir a eth
        s_contractBalance -= arss_inEth;        //Convertir a eth
        s_depositCount -= 1;
        
        emit Account_WithdrowOk(msg.sender, _value);
    }	

    function _getARSSPrice() private view returns(int256 _latestAnswer) {
        int256 arss_9dec = i_Oracle.latestAnswer();
        
        return _latestAnswer = arss_9dec * 10**9;

    }

}
