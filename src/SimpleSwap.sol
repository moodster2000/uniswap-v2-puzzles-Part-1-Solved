// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC20.sol";

contract SimpleSwap {
    /**
     *  PERFORM A SIMPLE SWAP WITHOUT ROUTER EXERCISE
     *
     *  The contract has an initial balance of 1 WETH.
     *  The challenge is to swap any amount of WETH for USDC token using the `swap` function
     *  from USDC/WETH pool and a slippage of 0.3%.
     *
     */
    function performSwap(address pool, address weth, address usdc) public {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);

        // Get reserves
        (uint112 reserveUSDC, uint112 reserveWETH, ) = pair.getReserves();

        // Calculate amount of USDC to receive using 0.3% slippage
        uint256 amountWETH = 1 ether; // Swap 1 WETH
        uint256 amountUSDCOut = getAmountOut(amountWETH, reserveWETH, reserveUSDC);

        // Ensure there is enough WETH in the contract
        require(IERC20(weth).balanceOf(address(this)) >= amountWETH, "Insufficient WETH balance");

        // Transfer WETH to the pair contract
        IERC20(weth).transfer(pool, amountWETH);

        // Swap WETH for USDC
        (uint256 amount0Out, uint256 amount1Out) = pair.token0() == usdc ? (amountUSDCOut, uint256(0)) : (uint256(0), amountUSDCOut);
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997; // Uniswap fee is 0.3%
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }
}
