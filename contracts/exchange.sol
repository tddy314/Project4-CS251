// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import './token.sol';
import "hardhat/console.sol";


contract TokenExchange is Ownable {
    string public exchange_name = 'Cilantra';

    // TODO: paste token contract address here
    // e.g. tokenAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3
    address tokenAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3;                                  // TODO: paste token contract address here
    Token public token = Token(tokenAddr);                                

    // Liquidity pool for the exchange
    uint private token_reserves = 0;
    uint private eth_reserves = 0;

    // Fee Pools
    uint private token_fee_reserves = 0;
    uint private eth_fee_reserves = 0;

    // Liquidity pool shares
    mapping(address => uint) private lps;

    // For Extra Credit only: to loop through the keys of the lps mapping
    address[] private lp_providers;      

    // Total Pool Shares
    uint private total_shares = 0;

    // liquidity rewards
    uint private swap_fee_numerator = 3;                
    uint private swap_fee_denominator = 100;

    // Constant: x * y = k
    uint private k;

    uint private multiplier = 10**5;
    uint private mul_bonus = 10 ** 18;

    constructor() {}
    

    // Function createPool: Initializes a liquidity pool between your Token and ETH.
    // ETH will be sent to pool in this transaction as msg.value
    // amountTokens specifies the amount of tokens to transfer from the liquidity provider.
    // Sets up the initial exchange rate for the pool by setting amount of token and amount of ETH.
    function createPool(uint amountTokens)
        external
        payable
        onlyOwner
    {
        // This function is already implemented for you; no changes needed.

        // require pool does not yet exist:
        require (token_reserves == 0, "Token reserves was not 0");
        require (eth_reserves == 0, "ETH reserves was not 0.");

        // require nonzero values were sent
        require (msg.value > 0, "Need eth to create pool.");
        uint tokenSupply = token.balanceOf(msg.sender);
        require(amountTokens <= tokenSupply, "Not have enough tokens to create the pool");
        require (amountTokens > 0, "Need tokens to create pool.");

        token.transferFrom(msg.sender, address(this), amountTokens);
        token_reserves = token.balanceOf(address(this));
        eth_reserves = msg.value;
        k = token_reserves * eth_reserves;

        // Pool shares set to a large value to minimize round-off errors
        total_shares = 10**5;
        // Pool creator has some low amount of shares to allow autograder to run
        lps[msg.sender] = 100;
    }

    // For use for ExtraCredit ONLY
    // Function removeLP: removes a liquidity provider from the list.
    // This function also removes the gap left over from simply running "delete".
    function removeLP(uint index) private {
        require(index < lp_providers.length, "specified index is larger than the number of lps");
        lp_providers[index] = lp_providers[lp_providers.length - 1];
        lp_providers.pop();
    }

    // Function getSwapFee: Returns the current swap fee ratio to the client.
    function getSwapFee() public view returns (uint, uint) {
        return (swap_fee_numerator, swap_fee_denominator);
    }

    // Function getReserves
    function getReserves() public view returns (uint, uint) {
        return (eth_reserves, token_reserves);
    }

    // ============================================================
    //                    FUNCTIONS TO IMPLEMENT
    // ============================================================
    
    /* ========================= Liquidity Provider Functions =========================  */ 
    uint mul = 10**5;
    // Function addLiquidity: Adds liquidity given a supply of ETH (sent to the contract as msg.value).
    // You can change the inputs, or the scope of your function, as needed.
    function addLiquidity(uint max_exchange_rate, uint min_exchange_rate) 
        external 
        payable
    {
        uint eth_in = msg.value;
        uint token_in = eth_in * token_reserves / eth_reserves;
        address sender = msg.sender;

        uint current_exchange_rate = eth_in * mul ;
        require(min_exchange_rate * mul_bonus * token_in <= current_exchange_rate && current_exchange_rate <= max_exchange_rate * mul_bonus * token_in, "The exchange rate must be in the range!");

        require(eth_in <= sender.balance, "Not enough ETH!");
        require(token_in <= token.balanceOf(msg.sender), "Not enough token!");
        require(eth_in > 0, "Amount of ETH must be positive!");

        uint share_in = eth_in * total_shares / eth_reserves;
        total_shares += share_in;
        lps[sender] += share_in;

        eth_reserves += eth_in;
        token_reserves += token_in;
        k = eth_reserves * token_reserves;

        bool existed = false;
        for(uint i = 0; i < lp_providers.length; i++) {
            if(lp_providers[i] == sender) {
                existed = true;
                break;
            }
        } 

        if(!existed) lp_providers.push(sender);

        token.transferFrom(sender, address(this), token_in);
    }


    // Function removeLiquidity: Removes liquidity given the desired amount of ETH to remove.
    // You can change the inputs, or the scope of your function, as needed.
    function removeLiquidity(uint eth_out, uint max_exchange_rate, uint min_exchange_rate)
        public 
        payable
    {
        /******* TODO: Implement this function *******/
        
        address sender = msg.sender;
        require(lps[sender] > 0, "You don't have any liquidity in pool!");
        
        require(eth_out < eth_reserves, "You cannot withdraw more ETH than the pool's reserve");
        uint token_out = eth_out * token_reserves / eth_reserves;
        require(token_out < token_reserves, "You cannot withdraw more Tokens than the pool's reserve");

        uint max_eth_out = eth_reserves * lps[sender] / total_shares;
        require(eth_out > 0, "You are not able to remove 0 liquidity!");
        require(eth_out < max_eth_out, "You are not allow to remove more liquidity than you are entitled to! Please use removeAllliquidity instead if you wish to withdraw all your tokens!");
        
        uint max_token_out = token_reserves * lps[sender] / total_shares;
        require(token_out < max_token_out, "You are not allow to remove more liquidity than you are entitled to! Please use removeAllliquidity instead if you wish to withdraw all your tokens!");

        uint current_exchange_rate = eth_out * mul;
        require(min_exchange_rate * mul_bonus * token_out <= current_exchange_rate && current_exchange_rate <= max_exchange_rate * mul_bonus * token_out, "The exchange rate must be in the range!");

        uint share_out = total_shares * eth_out / eth_reserves;
        lps[sender] -= share_out;
        total_shares -= share_out;

        eth_reserves -= eth_out;
        token_reserves -= token_out;
        k = eth_reserves * token_reserves;

        payable(sender).transfer(eth_out);
        token.transfer(sender, token_out);

    }

    // Function removeAllLiquidity: Removes all liquidity that msg.sender is entitled to withdraw
    // You can change the inputs, or the scope of your function, as needed.
    function removeAllLiquidity(uint max_exchange_rate, uint min_exchange_rate)
        external
        payable
    {
        /******* TODO: Implement this function *******/
        address sender = msg.sender;
        require(lps[sender] > 0, "You don't have any liquidity in pool!");

        uint eth_out = eth_reserves * lps[sender] / total_shares;
        uint token_out = eth_out * token_reserves / eth_reserves;

        require(eth_out < eth_reserves, "You cannot withdraw all ETH in the pool!");
        require(token_out < token_reserves, "You cannot withdraw all Tokens in the pool!");
        
        uint current_exchange_rate = eth_out * mul;
        require(min_exchange_rate * mul_bonus * token_out <= current_exchange_rate && current_exchange_rate <= max_exchange_rate * mul_bonus * token_out, "The exchange rate must be in the range!");


        total_shares -= lps[sender];
        lps[sender] = 0;

        eth_reserves -= eth_out;
        token_reserves -= token_out;
        k = eth_reserves * token_reserves;
        
        payable(sender).transfer(eth_out);
        token.transfer(sender, token_out);

        uint pos;
        for(uint i = 0; i < lp_providers.length; i++) {
            if(lp_providers[i] == sender) {
                pos = i;
                break;
            }
        }

        removeLP(pos);
    }
    /***  Define additional functions for liquidity fees here as needed ***/


    /* ========================= Swap Functions =========================  */ 

    // Function swapTokensForETH: Swaps your token with ETH
    // You can change the inputs, or the scope of your function, as needed.
    function swapTokensForETH(uint token_in, uint max_exchange_rate)
        external 
        payable
    {
        /******* TODO: Implement this function *******/
        address sender = msg.sender;
        require(token_in <= token.balanceOf(sender), "You don't have enough tokens to make this transaction");
        require(token_in > 0 , "You must use a positive amount of token!");

        uint eth_out = eth_reserves * token_in / (token_reserves + token_in) ;

        uint cur_rate = eth_out * mul;
        require(cur_rate <= max_exchange_rate * mul_bonus * token_in, "Big slippage to swap Tokens for ETH!");
        
        require(eth_out < eth_reserves, "You can not exchange for all eth in this pool!");
        
        uint fee = eth_out * swap_fee_numerator / swap_fee_denominator;
        
        token_reserves += token_in;
        eth_reserves -= eth_out;
        eth_out -= fee;
        eth_fee_reserves += fee;
        
        token.transferFrom(sender, address(this), token_in);
        payable(sender).transfer(eth_out);
    }

    // uint public check_token;

    // function setValue() external {
    //     token_reserves = 5000;
    //     eth_reserves = 5000*(10**18);
    // }

    // Function swapETHForTokens: Swaps ETH for your tokens
    // ETH is sent to contract as msg.value
    // You can change the inputs, or the scope of your function, as needed.
    function swapETHForTokens(uint max_exchange_rate)
        external
        payable 
    {
        /******* TODO: Implement this function *******/
        address sender = msg.sender;
        uint eth_in = msg.value;
        require(eth_in <= sender.balance, "You don't have enough ETH!");
        require(eth_in > 0, "You must use a positive amount of ETH!");

        uint token_out = token_reserves * eth_in / (eth_reserves + eth_in);  

        uint cur_rate = eth_in * mul;
        require(cur_rate <=  max_exchange_rate * mul_bonus * token_out, "Big slippage to swap ETH for Token!");
        
        require(token_out < token_reserves, "You can not exchange for all token in this pool!");
        
        uint fee = token_out * swap_fee_numerator / swap_fee_denominator;

        token_reserves -= token_out;
        eth_reserves += eth_in;
        token_out -= fee;
        token_fee_reserves += fee;
    
        token.transfer(sender, token_out);
    }
}