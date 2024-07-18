// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IERC20.sol";

/**
 *
 *  ARBITRAGE A POOL
 *
 * Given two pools where the token pair represents the same underlying; WETH/USDC and WETH/USDT (the formal has the corect price, while the latter doesnt).
 * The challenge is to flash borrowing some USDC (>1000) from `flashLenderPool` to arbitrage the pool(s), then make profit by ensuring MyMevBot contract's USDC balance
 * is more than 0.
 *
 */
contract MyMevBot {
    address public immutable flashLenderPool;
    address public immutable weth;
    address public immutable usdc;
    address public immutable usdt;
    address public immutable router;
    bool public flashLoaned;

    constructor(
        address _flashLenderPool,
        address _weth,
        address _usdc,
        address _usdt,
        address _router
    ) {
        flashLenderPool = _flashLenderPool;
        weth = _weth;
        usdc = _usdc;
        usdt = _usdt;
        router = _router;
    }

    function performArbitrage() public {
        // your code here
        uint256 amountToBorrow = 1100 * 1e6; // Borrowing 1000 USDC

        // Initiating a flash loan for 1000 USDC
        IUniswapV3Pool(flashLenderPool).flash(
            address(this), // recipient is this contract
            amountToBorrow, // amount of USDC to borrow
            0, // no WETH borrowed
            "" // no additional data
        );
    }

    function uniswapV3FlashCallback(
        uint256 _fee0,
        uint256,
        bytes calldata data
    ) external {
        callMeCallMe();
        uint256 borrowedAmount = IERC20(usdc).balanceOf(address(this));
        
        address[] memory pathBuy = new address[](2);
        address[] memory pathSell = new address[](2);
        pathBuy[0] = usdc;
        pathBuy[1] = weth;
        pathSell[0] = weth;
        pathSell[1] = usdc;

        // Buy WETH from WETH/USDT pool
        IUniswapV2Router(router).swapExactTokensForTokens(
            borrowedAmount,
            0, // Accept any amount of WETH (risky, usually would set a minimum)
            pathBuy,
            address(this),
            block.timestamp + 1 minutes
        );

        // Get the acquired WETH amount
        uint256 wethAmount = IERC20(weth).balanceOf(address(this));

        // Sell WETH on the WETH/USDC pool
        IUniswapV2Router(router).swapExactTokensForTokens(
            wethAmount,
            0, // Accept any amount of USDC (risky, usually would set a minimum)
            pathSell,
            address(this),
            block.timestamp + 1 minutes
        );

        uint256 repaymentAmount = borrowedAmount + _fee0;
        IERC20(usdc).transfer(flashLenderPool, repaymentAmount);

        // Check that profit condition is met
        uint256 finalUSDCBalance = IERC20(usdc).balanceOf(address(this));
        require(finalUSDCBalance > 0, "Arbitrage did not yield profit");
        // your code start here
    }

    function callMeCallMe() private {
        uint256 usdcBal = IERC20(usdc).balanceOf(address(this));
        require(msg.sender == address(flashLenderPool), "not callback");
        require(
            flashLoaned = usdcBal >= 1000 * 1e6,
            "FlashLoan less than 1,000 USDC."
        );
    }
}

interface IUniswapV3Pool {
    /**
     * recipient: the address which will receive the token0 and/or token1 amounts.
     * amount0: the amount of token0 to send.
     * amount1: the amount of token1 to send.
     * data: any data to be passed through to the callback.
     */
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface IUniswapV2Router {
    /**
     *     amountIn: the amount to use for swap.
     *     amountOutMin: the minimum amount of output tokens that must be received for the transaction not to revert.
     *     path: an array of token addresses. In our case, WETH and USDC.
     *     to: recipient address to receive the liquidity tokens.
     *     deadline: timestamp after which the transaction will revert.
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}
