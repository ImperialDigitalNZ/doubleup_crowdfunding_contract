pragma solidity ^0.4.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
contract ERC20Token is Owned {
    using SafeMath for uint;
    // ------------------------------------------------------------------------
    // Total Supply : total supply won't be calcuated when during crowdfunding
    // ------------------------------------------------------------------------
    uint256 _totalSupply = 0;

    // ------------------------------------------------------------------------
    // Balances for each account : balance of tokens won't be calculated 
    // during crowdfunding
    // ------------------------------------------------------------------------
    mapping(address => uint256) balances;

    // ------------------------------------------------------------------------
    // Owner of account approves the transfer of an amount to another account
    // ------------------------------------------------------------------------
    mapping(address => mapping (address => uint256)) allowed;

    // ------------------------------------------------------------------------
    // Get the total token supply
    // ------------------------------------------------------------------------
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the account balance of another account with address _owner
    // ------------------------------------------------------------------------
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from owner's account to another account
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount 
                && _amount > 0 
                && balances[_to] + _amount > balances[_to]
        ) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Allow _spender to withdraw from your account, multiple times, up to the
    // _value amount. If this function is called again it overwrites the
    // current allowance with _value.
    // ------------------------------------------------------------------------
    function approve(address _spender, uint256 _amount
    ) returns (bool success) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner's
    // balance to the spender's account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount 
            && allowed[_from][msg.sender] >= _amount 
            && _amount > 0 
            && balances[_to] + _amount > balances[_to]
        ) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address _owner, address _spender) 
    constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract CrowdFundingDoubleUp is ERC20Token {
    // token info
    string public constant name = "DOUP";
    string public constant symbol = "DOUP";
    uint8 public constant decimals = 2;

    // amount of raised money in wei
    uint256 public weiRaised;

    // funding periods
    uint256 public constant START_OF_ICO = 1506121200; 
    uint256 constant PRESALE_END = START_OF_ICO + 3 minutes;
    uint256 constant WEEK1_END = PRESALE_END + 3 minutes;
    uint256 constant WEEK2_END = WEEK1_END + 3 minutes;
    uint256 constant WEEK3_END = WEEK2_END + 3 minutes;
    uint256 constant WEEK4_END = WEEK3_END + 3 minutes;
    uint256 public constant END_OF_ICO = WEEK4_END;

    // maxium supply is set
    uint256 public constant MAX_SUPPLY_TOKEN = 10000000; // 100000 DOUP
    uint256 public constant MIN_CAP_ETHER = 200 * 1 ether; // 200 ether
    uint256 public constant CAP_FOR_70 = 50 * 1 ether; // 50 ether

    uint tokensPerEther = 0;


    // ------------------------------------------------------------------------
    // mapping of the either funded by each participant 
    // ------------------------------------------------------------------------
    mapping(address => mapping(uint8 => uint256)) contributes;
    mapping(address => mapping(uint8 => uint256)) balancePeriods;
    mapping(address => mapping(uint8 => uint256)) bonusBalances;

    uint8 constant KEY_PS = 11;
    uint8 constant KEY_W1 = 12;
    uint8 constant KEY_W2 = 13;
    uint8 constant KEY_W3 = 14;
    uint8 constant KEY_W4 = 15;

    function CrowdFundingDoubleUp() {
        balances[owner] = MAX_SUPPLY_TOKEN;
        _totalSupply = 0;
    }

    modifier hasEnded {
        require(now > END_OF_ICO);
        _;
    }

    function() payable {
        acceptFund(msg.sender);
    }
    // accept funding during crowdfunding
    function acceptFund(address participant) payable {
        require(participant != 0x0);
        
        uint256 at = now;
        // check entire periods
        require(vaildFundingPeriod(at));
        // check 1M reached in presale
        require(!stopPresale(now));

        uint8 periodKey = getPeriodKey(at);
        require(periodKey!=0);
        // set add contribute for participants
        contributes[participant][periodKey] = contributes[participant][periodKey].add(msg.value);
        weiRaised = weiRaised.add(msg.value);
    }
    // get keys by periods
    function getPeriodKey(uint256 at) returns (uint8) {
        if (at < START_OF_ICO) {
            return 0;
        }else if(at < PRESALE_END) {
            return KEY_PS;
        }else if(at < WEEK1_END) {
            return KEY_W1;
        }else if(at < WEEK2_END) {
            return KEY_W2;
        }else if(at < WEEK3_END) {
            return KEY_W3;
        }else if(at < WEEK4_END) {
            return KEY_W4;
        }else {
            return 0;
        }
    }

    // get bonus rate by current time
    function getBonusRate(uint8 periodKey) internal constant returns (uint) {
        if(periodKey == KEY_PS) {
            return 70;
        }else if(periodKey == KEY_W1) {
            return 20;
        }else if(periodKey == KEY_W2) {
            return 15;
        }else if(periodKey == KEY_W3) {
            return 10;
        }else if(periodKey == KEY_W4) {
            return 5;
        }else {
            return 0;
        }
    }

    function stopPresale(uint256 at) internal constant returns (bool) {
        if(at > START_OF_ICO && at < PRESALE_END) {
            if(weiRaised >= CAP_FOR_70) {
                return true;
            }
        }
        return false;
    }
    // validation 
    function vaildFundingPeriod(uint256 at) internal constant returns (bool) {
        return msg.value != 0 && at > START_OF_ICO && at < END_OF_ICO;
    }

    
    // ------------------------------------------------------------------------------- //
    // after funding 
    // ------------------------------------------------------------------------------- //
    // set token amount for 1 ether 
    // Notice : if token amount set already, then never change it.
    // the argument value must be based on token, not DOUP!! Yes 1000 tokens, not 10 DOUP
    function setTokensPerEther(uint _tokenAmount) onlyOwner {
        require(now > END_OF_ICO);
        require(tokensPerEther==0);
        require(_tokenAmount > 0);

        tokensPerEther = _tokenAmount;
    }
    // should decide whether transfer balance after ICO or end of every period
    function distributeBalance(address addr) onlyOwner {
        require(now > END_OF_ICO);
        require(tokensPerEther > 0);
        require(getBalance(addr) == 0); // only once distributed

        uint256 _etherContributed = getTotalContribution(addr);  // total contribute of entire periods
        
        require(_etherContributed > 0);

        uint256 participantTotalBalance = getTotalBalance(addr);

        require(participantTotalBalance > 0);
        // send tokens
        transfer(addr, participantTotalBalance);
        // get ether from contract to the owner address
        owner.transfer(_etherContributed);
    }

    function getBalance(address addr) hasEnded returns (uint256) {
        return balanceOf(addr);
    }
    // return total token amount (including bonus) for each participant
    function getTotalBalance(address addr) hasEnded returns (uint256) {
        require(tokensPerEther > 0);

        if(contributes[addr][KEY_PS] > 0) {
            balancePeriods[addr][KEY_PS] = tokensPerEther.mul(contributes[addr][KEY_PS]).div(1 ether);
            if(balancePeriods[addr][KEY_PS] > 0) {
                bonusBalances[addr][KEY_PS] = (balancePeriods[addr][KEY_PS] * getBonusRate(KEY_PS)) / 100;
            }
            
        }
        if(contributes[addr][KEY_W1] > 0) {
            balancePeriods[addr][KEY_W1] = tokensPerEther.mul(contributes[addr][KEY_W1]).div(1 ether);
            if(balancePeriods[addr][KEY_W1] > 0) {
                bonusBalances[addr][KEY_W1] = (balancePeriods[addr][KEY_W1] * getBonusRate(KEY_W1)) / 100;
            }
        }
        if(contributes[addr][KEY_W2] > 0) {
            balancePeriods[addr][KEY_W2] = tokensPerEther.mul(contributes[addr][KEY_W2]).div(1 ether);
            if(balancePeriods[addr][KEY_W2] > 0) {
                bonusBalances[addr][KEY_W2] = (balancePeriods[addr][KEY_W2] * getBonusRate(KEY_W2)) / 100;
            }
        }
        if(contributes[addr][KEY_W3] > 0) {
            balancePeriods[addr][KEY_W3] = tokensPerEther.mul(contributes[addr][KEY_W3]).div(1 ether);
            if(balancePeriods[addr][KEY_W3] > 0) {
                bonusBalances[addr][KEY_W3] = (balancePeriods[addr][KEY_W3] * getBonusRate(KEY_W3)) / 100;
            }
        }
        if(contributes[addr][KEY_W4] > 0) {
            balancePeriods[addr][KEY_W4] = tokensPerEther.mul(contributes[addr][KEY_W4]).div(1 ether);
            if(balancePeriods[addr][KEY_W4] > 0) {
                bonusBalances[addr][KEY_W4] = (balancePeriods[addr][KEY_W4] * getBonusRate(KEY_W4)) / 100;
            }
        }

        uint256 netBalance = balancePeriods[addr][KEY_PS].add(balancePeriods[addr][KEY_W1])
                                .add(balancePeriods[addr][KEY_W2]).add(balancePeriods[addr][KEY_W3])
                                .add(balancePeriods[addr][KEY_W4]);

        uint256 totalBonus = bonusBalances[addr][KEY_PS].add(bonusBalances[addr][KEY_W1])
                        .add(bonusBalances[addr][KEY_W2]).add(bonusBalances[addr][KEY_W3])
                        .add(bonusBalances[addr][KEY_W4]);

        return netBalance.add(totalBonus);
    }

    // return the either (wei) of a participant
    function getTotalContribution(address addr) hasEnded returns (uint256) {
        return contributes[addr][KEY_PS]
        .add(contributes[addr][KEY_W1])
        .add(contributes[addr][KEY_W2])
        .add(contributes[addr][KEY_W3])
        .add(contributes[addr][KEY_W4]);
    }

    // test
    function stopPresaleTest() constant returns (bool) {
        return stopPresale(now);
    }

    function getTokenPerEther() constant returns (uint) {
        return tokensPerEther;
    }
    
    // test
    function getCurrentPeriodTest() returns (uint256 at, string period, uint256 icoperiod) {
        at = now;
        if (at < START_OF_ICO) {
            icoperiod = START_OF_ICO;
            period = "now started";
        }else if(at < PRESALE_END) {
            icoperiod = PRESALE_END;
            period = "presale";
        }else if(at < WEEK1_END) {
            icoperiod = WEEK1_END;
            period = "week1";
        }else if(at < WEEK2_END) {
            icoperiod = WEEK2_END;
            period = "week2";
        }else if(at < WEEK3_END) {
            icoperiod = WEEK3_END;
            period = "week3";
        }else if(at < WEEK4_END) {
            icoperiod = WEEK4_END;
            period = "week4";
        }else {
            period = "ICO done";
        }
    }
   
}
