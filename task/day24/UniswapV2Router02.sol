// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IUniswapV2Factory.sol';
import './interfaces/TransferHelper.sol';
import './interfaces/IUniswapV2Router02.sol';
import './libraries/UniswapV2Library.sol';
import './libraries/SafeMath.sol';
// import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import { console } from "forge-std/Test.sol";


contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeMath for uint;
    // UniswapFactory合约地址
    // address public immutable override factory;   
    address public immutable factory;
    // WETH合约地址
    // address public immutable override WETH;
    address public immutable WETH;
    // 确保时间是有效的，即大于新区块产生时的时间戳
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        // 仅通过WETH合同的回退接受ETH
        assert(msg.sender == WETH);
    }

    /**
     * @dev 根据两种token的地址向其交易对添加流动性
     * @param tokenA tokenA地址
     * @param tokenB tokenB地址
     * @param amountADesired 期望添加tokenA的数量
     * @param amountBDesired 期望添加tokenB的数量
     * @param amountAMin 愿意接受的最低tokenA数量，用于控制滑点
     * @param amountBMin 愿意接受的最低tokenB数量，用于控制滑点
     * @return amountA 实际添加到资金池中tokenA的数量
     * @return amountB 实际添加到资金池中tokenB的数量
     */ 
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // 拿到lpToken的地址，若不存在则创建一个交易对
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        // 获取两种token的储备量
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // 根据两种token的储备量和期望tokenA的数额获取tokenB最佳的数额
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            // 如果amountBOptimal不大于amountBDesired并且amountBOptimal不小于amountBMin，则返回amountADesired, amountBOptimal
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                // 如果amountBOptimal大于amountBDesired，则根据两种token的储备量和期望tokenB的数额获取tokenA最佳的数额
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                // 断言
                assert(amountAOptimal <= amountADesired);
                // 并且amountAOptimal不小于amountAMin，则返回amountAOptimal, amountBDesired
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    
    // 添加流动性： 两个 token
    /**
     * @dev 根据两种token的地址向其交易对添加流动性
     * @param tokenA tokenA地址
     * @param tokenB tokenB地址
     * @param amountADesired 期望添加tokenA的数量
     * @param amountBDesired 期望添加tokenB的数量
     * @param amountAMin 愿意接受的最低tokenA数量
     * @param amountBMin 愿意接受的最低tokenB数量
     * @param to 接受lptoken的地址
     * @param deadline 交易允许最后执行时间
     * @return amountA 实际添加到资金池中tokenA的数量
     * @return amountB 实际添加到资金池中tokenB的数量
     * @return liquidity 获得lptoken的数量
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin, 
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);

        // 转账两种token的amount数量到pair合约，如果用户代币数量不足，则转账失败，抛出异常
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);

        // 向to地址铸造lptoken
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    // 添加流动性： token 和 ETH
    /**
     * @dev 根据token的地址向其与WETH合约的交易对添加流动性
     * @param token token地址
     * @param amountTokenDesired 期望添加token的数量
     * @param amountTokenMin 愿意接受的最低token数量
     * @param amountETHMin 愿意接受的最低ETH数量
     * @param to 接受lptoken的地址
     * @param deadline 交易允许最后执行时间
     * @return amountToken 实际添加到资金池中token的数量
     * @return amountETH 实际添加到资金池中ETH的数量
     * @return liquidity 获得lptoken的数量
     */
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin, // 最低ETH数量:为什么需要这个参数：这是两个token添加到流动性池子中，既然要最少token这个参数，那么最少eth参数也是必须要的。
        address to,
        uint deadline
    ) external payable virtual override ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        // 首次是创建池子，再次添加流动性这个函数没啥作用，这个函数主要是获得期望获得两个代币的数量
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));

        // 查询 pair地址 在两个token的存款
        (, bytes memory data) = WETH.call(abi.encodeWithSelector(bytes4(keccak256("balanceOf(address)")), pair));
        uint256 wethBalance = abi.decode(data, (uint256));
        console.log("pair weth balance:", wethBalance);
        (, bytes memory data1) = token.call(abi.encodeWithSelector(bytes4(keccak256("balanceOf(address)")), pair));
        uint256 tokenBalance = abi.decode(data1, (uint256));
        console.log("pair token balance:", tokenBalance);

        // 铸造lptoken，并且会修改pair合约的储备量和时间戳
        liquidity = IUniswapV2Pair(pair).mint(to);
        console.log("pair liquidity:", IUniswapV2Pair(pair).balanceOf(to));

        // 如果转入ETH有多余的，退还
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // 移除流动性： 两个 token
    /**
     * @dev 根据两种token的地址向其交易对移除流动性
     * @param tokenA tokenA地址
     * @param tokenB tokenB地址
     * @param liquidity 移除lptoken的数量
     * @param amountAMin 愿意接受的最低tokenA数量，用于控制滑点
     * @param amountBMin 愿意接受的最低tokenB数量，用于控制滑点
     * @param to 接受两种token的地址
     * @param deadline 交易允许最后执行时间
     * @return amountA 移除流动性获得tokenA的数量
     * @return amountB 移除流动性获得tokenB的数量
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // 将lptoken发送到pair合约
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
        // 销毁lptoken，返回销毁lptoken获得两种token的数量
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        // 判断返回数量是否大于所设置的最小返回值
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
    
    // 移除流动性： token 和 ETH
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        // 先将返回的token和ETH发送到当前合约
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),   // 将 两种代币 发送到 Router合约，然后Router在将两种代币发给用户。
            deadline
        );
        // 转到to地址
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    // 移除流动性： 两个 token，  这个方法支持用户在不预先授权的情况下移除流动性，通过permit功能进行身份验证
    /**
     * @dev 相对于removeLiquidity引入了许可功能进行身份验证
     * @param tokenA tokenA地址
     * @param tokenB tokenB地址
     * @param liquidity 移除lptoken的数量
     * @param amountAMin 愿意接受的最低tokenA数量
     * @param amountBMin 愿意接受的最低tokenB数量
     * @param to 接受两种token的地址
     * @param deadline 交易允许最后执行时间
     * @param approveMax 用于指示是否在移除流动性之前使用permit功能进行身份验证
     * @param v 原始签名的v
     * @param r 原始签名的r
     * @param s 原始签名的s
     * @return amountA 移除流动性获得tokenA的数量
     * @return amountB 移除流动性获得tokenB的数量
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        // uint value = approveMax ? uint(-1) : liquidity;  // 0.8.0 之前版本
        uint value = approveMax ? type(uint).max : liquidity;
        // 身份验证
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    // 移除流动性： token 和 ETH，  这个方法支持用户在不预先授权的情况下移除流动性，通过permit功能进行身份验证
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        // uint value = approveMax ? uint(-1) : liquidity;
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // 移除流动性：token 和 ETH， 这个方法处理的是：有些token在进行转账时，会收费，所以需要这个方法
    // 移除流动性（支持转账手续费代币）：相对于removeLiquidityETH适用于处理在资金池中具有“费用分摊”（fee-on-transfer）机制的代币
    // 参数：token: 需要移除的token地址, liquidity: 移除的lptoken数量, amountTokenMin: 愿意接受的最低token数量, amountETHMin: 愿意接受的最低ETH数量, to: 接受两种token的地址, deadline: 交易允许最后执行时间
    // 返回：amountETH: 移除流动性获得ETH的数量
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    // 移除流动性：token 和 ETH， 这个方法支持： Fee-on-transfer + Permit 功能
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        // uint value = approveMax ? uint(-1) : liquidity;  // 0.8.0 之前版本
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // 兑换 ： 提取的公方法
    /**
     * @dev 根据path路径和其amounts量进行交易对兑换
     * @param amounts 在每对交易对进行输入的token的数量，对应path
     * @param path 当没有两种token的交易对，需要进行多个兑换(tokenA->tokenB->ETH)
     * @param _to 接受兑换token的地址
     */
    // 注意一般是不直接调用这个函数，这个函数是由别的函数调用，在调用这个函数之前，支付的代币已经转给pair合约了
    // amounts[0] = 付出量  amounts[1] = 用户收到量(理想情况：只减去了手续费，没有滑点造成的损失)
    // path[0] = 代币地址  path[1] = 代币地址
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        // 循环path路径
        // 当path.length>2时，即：用户向tokenA->tokenC,但是没有这个池子，不过呢，存在tokenA->tokenB和tokenB->tokenC池子
        for (uint i; i < path.length - 1; i++) {
            // 计算每对交易对的兑换量 
            (address input, address output) = (path[i], path[i + 1]);
            // 两个代币地址排序，token0是较小的，token1是较大的（这里减少变量，没写token1）
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            // 因为path[0]一定是付出地址，path[1]一定是收到量，现在如果input == token0，那么amount0Out = 0，amount1Out = amountOut，否则相反
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            // 如果中间还有其他的路径，to地址为其中交易对的pair地址
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            // 进行兑换
            // 用户想要 支出 token0，收入 token1。那么参数就是 (amount0Out = 0, amount1Out = X)。
            // 用户想要 支出 token1，收入 token0。那么参数就是 (amount0Out = Y, amount1Out = 0)。
            // 注意用想要token0，那么执行pair合约swap函数之前，我们的token1便转给pair合约了
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    // -------------------------下面两个方法都确切Token换Token--------------------------

    // 兑换1（确切输入）：根据确切Token兑换Token。意思是：用户用 100usdt，计算能获得 x个 ETH，假如 合约计算出来的数量小于用户愿意接受的最低数量，那么交易失败。
    /**
     * @dev 根据确切的tokenA的数量兑换tokenB
     * @param amountIn 进行兑换的tokenA的数量
     * @param amountOutMin 愿意接受兑换后的最低tokenB数量，用于控制滑点
     * @param path 进行兑换的路径
     * @param to 接受兑换后获得tokenB的地址
     * @param deadline 交易允许最后执行时间
     * @return amounts 根据path路径获得每对交易对获得的token，最后一个为获得兑换后tokenB的数量
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        // 探究这个方法中两个数组：path 和 amounts：
        // Path数组：每个元素都是一个 token 代币地址。
        //   假如用户想要用 usdt兑换 ETH，但是交易对没有 usdt->Doge 的交易对，但是有 usdt->ETH 和 ETH->Doge 的交易对。
        //   那么path数组就是 [Addr_usdt, Addr_ETH, Addr_Doge]。同理，假如用户想要 usdt兑换 BTC，但是交易对没有 usdt->BTC 的交易对，但是有 usdt->Doge 和 Doge->ETH， ETH->BTC 的交易对。
        //   那么path数组就是 [Addr_usdt, Addr_Doge, Addr_ETH, Addr_BTC]。
        // Amounts数组：每个元素都是一个 代币数量。
        //   假如用户想要用 100 usdt 兑换 Doge，那么amounts数组就是 [100, arg1, arg2]。arg1是ETH数量，arg2是Doge数量。
        //   100是用户付出的usdt，arg1和arg2是合约计算出来的，100usdt 能兑换 arg1数量的ETH，然后 arg1个eth 能兑换 arg2数量的Doge。
        // 注意：代币交易过程中，是会计算手续费的，收取规则997/1000。
        // 注意：多路径的话，手续费会多次收取。
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        // 判断最终获得的tokenB的数量是否大于amountOutMin
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // 将tokenA转给pair合约
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]  // 计算能获得的代币数量，然后转给pair合约
        );
        // 兑换
        _swap(amounts, path, to);
    }

    // 兑换1-1（确切输出）：用户需要确切个 Token数量:。意思是：用户需要 1ETH的话，愿意用 Max_Amounts个 usdt 兑换，
    //   假如合约计算出来的数量大于 Max_Amounts，那么交易失败。
    /**
     * @dev 根据需要获得确切数量的tokenB传入需要tokenA的数量
     * @param amountOut 需要兑换后获得tokenB的数量
     * @param amountInMax 愿意接受兑换后的最高tokenA数量，用于控制滑点
     * @param path 进行兑换的路径
     * @param to 接受兑换后获得tokenB的地址
     * @param deadline 交易允许最后执行时间
     * @return amounts 根据path路径获得每对交易对获得的token，第一个为需要输入的tokenA数量
     */
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        // 计算amounts，从后往前计算
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    // -------------------------下面两个方法都确切ETH换Token----------------------------

    // 兑换2（确切输入）：根据确切数量的ETH的兑换token
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    // 兑换2-2（确切输出）：根据需要获得确切数量的ETH 传入 需要token的数量
    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    // -------------------------下面两个方法都确切Token换ETH----------------------------

    // 兑换3（确切输入）：根据确切数量的token的兑换ETH
    // 获取期望的eth数量 -》 token转账 -》 然后进行兑换 -》获得 weth
    function swapExactTokensForETH(
        uint amountIn,  // 输入的token数量
        uint amountOutMin,  // 最小eth数量，如果小于这个数量，那么交易失败
        address[] calldata path,  // 两个token的地址  path[0] = tokenAddr   path[1] = wethAddr
        address to,  // 接收eth的地址
        uint deadline  // 交易允许最后执行时间
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0],  // 合约地址
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]  // 计算能获得的代币数量，然后转给pair合约
        );
        _swap(amounts, path, address(this));  // 注意address(this)是当前合约地址，在pair合约中的swap方法中，他将weth转给router合约
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);  // 减少 weth
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]); 
    }

    // 兑换3-3（确切输出）：根据需要获得确切数量的token传入需要ETH的数量
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // -------------------------下面方法支持转账手续费--------------------------------
    //   确切输出的话，就不支持转账手续费。而确切输入的话，就支持转账手续费。
    //     例如：市场价：(100usdt-1ETH)，现在用户想要 1ETH，用户最多能接受103Usdt。
    //       假如确认输出 1ETH，合约计算需要输入103usdt。刚好用户可以接受，用户便将103usdt授权给Router合约。
    //       Router将103转给Pair合约时 由于Token转账时要收费的，导致Pair合约只接收到了 103*0.95 = 97.85个usdt。
    //       用户只能获得0.9785个ETH。现在的问题是：用户本来可以得到1ETH，现在只能获得0.9785个ETH。用户肯定不同意。
    //       
    //       如果开发者硬要写的确切输出的话，你可以参考swapExactTokensForTokensSupportingFeeOnTransferTokens这个方法：
    //       这个方法是在兑换完成后，在进行判断：兑换后to地址的ETh的余额-to地址之前的ETH >= amountOutMin用户能接受的最低ETH数量
    // -----------------------------------------------------------------------------

    // 兑换（支持转账收费令牌）
    // 要求初始金额已经发送到第一对
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        // 循环path路径
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            {
                // 避免堆栈太深的错误
                // 获取交易对两种token的储备对
                (uint reserve0, uint reserve1, ) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                // 获取用户传入tokenA的数量
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                // 根据用户传入tokenA的数量获取另一token的数量
                amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // 兑换4（确切输入）：根据确切的tokenA的数量兑换tokenB
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        // 将tokenA传入pair合约地址
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amountIn
        );
        // 兑换前to地址的tokenB的余额
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        // 兑换
        _swapSupportingFeeOnTransferTokens(path, to);
        // 兑换后to地址的tokenB的余额-balanceBefore需要 >= amountOutMin
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    // 兑换4-1（确切输入）：根据确切的ETH的数量兑换tokenB
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable virtual override ensure(deadline) {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    // 兑换4-2（确切输入）：根据确切的token的数量兑换ETH
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // 兑换4-4 和 兑换4功能一样
    // 超：实现的：因多跳产生的转账收费余额结算，避免因 手续费导致金额偏差
    function swapExactTokensForTokensSupportingFeeOnTransferTokens_new(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
    
        // 1. 记录转账前Pair的余额
        address firstPair = UniswapV2Library.pairFor(factory, path[0], path[1]);
        uint balanceBefore = IERC20(path[0]).balanceOf(firstPair);
    
        // 2. 转账用户指定的数量
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            firstPair,
            amountIn
        );
        
        // 3. 计算实际到账数量（处理Fee-on-Transfer）
        uint actualAmountIn = IERC20(path[0]).balanceOf(firstPair).sub(balanceBefore);
        
        // 4. 基于实际到账数量计算输出
        amounts = UniswapV2Library.getAmountsOut(factory, actualAmountIn, path);
        
        // 5. 检查最小输出要求
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        
        // 6. 执行交换
        _swapSupportingFeeOnTransferTokens(path, to);
    }


    // -------------------------下面方法提供给前端用的-------------------------------

    // 库函数
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual override returns (uint amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual override returns (uint amountIn) {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) public view virtual override returns (uint[] memory amounts) {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) public view virtual override returns (uint[] memory amounts) {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}
