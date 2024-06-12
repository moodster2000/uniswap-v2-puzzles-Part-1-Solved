// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AddLiquid {
    /**
     *  ADD LIQUIDITY WITHOUT ROUTER EXERCISE
     *
     *  The contract has an initial balance of 1000 USDC and 1 WETH.
     *  Mint a position (deposit liquidity) in the pool USDC/WETH to msg.sender.
     *  The challenge is to provide the same ratio as the pool then call the mint function in the pool contract.
     *
     */
    function addLiquidity(address usdc, address weth, address pool, uint256 usdcReserve, uint256 wethReserve) public {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);

        // your code start here
        // Get reserves from the pair contract
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        // Determine which reserve is USDC and which is WETH
        (uint256 usdcReserveCurrent, uint256 wethReserveCurrent) = usdc < weth ? (reserve0, reserve1) : (reserve1, reserve0);

        // Calculate amount of USDC and WETH needed to add in the same ratio as the current pool
        uint256 amountUSDC = (usdcReserveCurrent * usdcReserve) / wethReserveCurrent;
        uint256 amountWETH = wethReserve;

        // Transfer USDC and WETH to the pair contract
        require(IERC20(usdc).transferFrom(msg.sender, address(this), amountUSDC), "USDC transfer failed");
        require(IERC20(weth).transferFrom(msg.sender, address(this), amountWETH), "WETH transfer failed");

        // Approve the pair contract to transfer the tokens from this contract
        IERC20(usdc).approve(pool, amountUSDC);
        IERC20(weth).approve(pool, amountWETH);

        // Transfer the tokens to the pair contract
        IERC20(usdc).transfer(pool, amountUSDC);
        IERC20(weth).transfer(pool, amountWETH);

        // Mint the liquidity tokens to msg.sender
        pair.mint(msg.sender);
        // see available functions here: https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol

        // pair.getReserves();
        // pair.mint(...);
    }
}
