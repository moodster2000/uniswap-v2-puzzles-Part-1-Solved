// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC20.sol";
import {console2} from "forge-std/Test.sol";


contract AddLiquidWithRouter {
    /**
     *  ADD LIQUIDITY WITH ROUTER EXERCISE
     *
     *  The contract has an initial balance of 1000 USDC and 1 ETH.
     *  Mint a position (deposit liquidity) in the pool USDC/ETH to `msg.sender`.
     *  The challenge is to use Uniswapv2 router to add liquidity to the pool.
     *
     */
    address public immutable router;

    constructor(address _router) {
        router = _router;
    }

    function addLiquidityWithRouter(address usdcAddress, uint256 deadline) public {
        // Ensure the provided deadline is not in the past
        require(deadline >= block.timestamp, "Invalid deadline");

        // Get the balance of USDC and ETH in the contract
        uint256 usdcAmount = IERC20(usdcAddress).balanceOf(address(this));
        uint256 ethAmount = address(this).balance;

        //calculate reserve ratio
        (uint256 reserveUSDC, uint256 reserveETH,) = IUniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc).getReserves(); //is it okay to hardcode the address?
        uint256 requiredEthAmount = (usdcAmount * reserveETH) / reserveUSDC;

        // Calculate minimum amounts with a 5% slippage tolerance
        uint256 amountUSDCMin = (usdcAmount * 95) / 100; // 5% less than the current amount
        uint256 amountETHMin = (requiredEthAmount * 95) / 100; // 5% less than the required amount

        console2.log(amountETHMin);
        console2.log(amountUSDCMin);

        // Approve the router to spend USDC
        IERC20(usdcAddress).approve(router, usdcAmount);

        // Add liquidity
        IUniswapV2Router(router).addLiquidityETH{ value: ethAmount }(
            usdcAddress,
            usdcAmount,
            amountUSDCMin,
            amountETHMin,
            msg.sender,
            deadline
        );
    }

    receive() external payable {}
}

interface IUniswapV2Router {
    /**
     *     token: the usdc address
     *     amountTokenDesired: the amount of USDC to add as liquidity.
     *     amountTokenMin: bounds the extent to which the ETH/USDC price can go up before the transaction reverts. Must be <= amountUSDCDesired.
     *     amountETHMin: bounds the extent to which the USDC/ETH price can go up before the transaction reverts. Must be <= amountETHDesired.
     *     to: recipient address to receive the liquidity tokens.
     *     deadline: timestamp after which the transaction will revert.
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}
