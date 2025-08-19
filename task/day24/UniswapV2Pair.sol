// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import './interfaces/IUniswapV2Pair.sol';
import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

// 执行操作到了pair合约中的函数，说明token已经转移到了pair合约地址中，所有pair只需要更新。
//   例如其他合约调用swarp函数，说明pair已经接收到了token0/token1的数量，现在pair只需要将自己持有的token1/token0转移到to地址，并更新储备量即可
contract UniswapV2Pair is UniswapV2ERC20 {
    using SafeMath for uint;
    using UQ112x112 for uint224;
    // 用于表示流动性池中的最小流动性份额，首次添加流动性时，
    //   用户的流动性代币数量必须大于这个值，不大于这个值得话会报错（程序员认为抛出错误）：溢出
    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    //对应的UniswapV2Factory合约地址
    address public factory;
    // 交易对中的两个token地址
    address public token0;
    address public token1;
    // 两个token在交易对中的储备量
    uint112 private reserve0;
    uint112 private reserve1;
    // 相对于上一次更新储备量的时间间隔？？？？我看源代码并不是时间间隔，而是当下时间
    uint32 private blockTimestampLast;
    // 价格累计值（算一段时间内的价格差），TWAP = 单位时间内价格差/ 时间差
    // 为什么需要WTAP (时间加权平均价格)：1.防止闪电贷操作价格  2.其他合约（如预言机）可以通过两次查询 priceCumulativeLast 和时间戳来计算 TWAP
    // TWAP 易受区块时间戳操纵影响，建议结合多个区块验证（如取中间值）
    // 如：开始price1=100，time1=100， 结束price1=200，time2=200    那么TWAP = (200-100)/(200-100) = 1,那么过去100秒的平均价格是 1，
    // 时间越长，那么平均价格越接近真实价格，建议区多个时间段的平均值，防止短时间内价格操纵（闪电贷：作恶人突然拉高价格，用户接盘买入，买入的代币恰好又是做恶人出售的，这样做恶人便套利）
    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    // 常量乘积模型的k值
    uint public kLast;
    uint private unlocked = 1;
    // 防重入锁
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // 获取token在交易对中的储备量和相对于上一次更新储备量的时间间隔
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // 转账token函数
    // 参数：token:进行转账的token地址，to:接受转账的地址，value:转账的数量
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() {
        factory = msg.sender;
    }

    // 在部署时由工厂调用一次
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // 更新数据有：token0、token1的储备量，距离上次更新时间间隔，更新时间加权平均价格
    // 参数：balance0:更新后tokenA的储备量，balance1:更新后tokenA的储备量，_reserve0:当前tokenA的储备量，_reserve1:当前tokenB的储备量
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        // uint112(-1) ：-1 表示全部为 1，即 112位 都是 1。
        // require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');  // 0.8.0 之前版本
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'UniswapV2: OVERFLOW');
        // 取时间戳的低 32 位
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        // 时间间隔更新
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        // 用于更新 ​累积价格（priceCumulativeLast）​​ 的逻辑，主要用于 ​TWAP（时间加权平均价格）​​ 计算
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // 永远不会溢出，+ overflow是理想的
            // priceCumulativeLast += ((_reserve1 * 2 ** 112 ) / _reserve0 ) * timeElapsed
            // UQ112x112.encode(_reserve1)：将 _reserve1 转换位为 UQ112x112 定点数（112位整数 ＋ 112位小数）
            // uqdiv(_reserve0)：将 UQ112x112 定点数除以 _reserve0，得到一个新的 UQ112x112 定点数
            // timeElapsed：乘以时间差，表示价格在 timeElapsed 时间内的累积值。
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // 如果打开收费功能，就约等于1/6的增长的根号(k)
    // 参数：_reserve0:tokenA的储备量，_reserve1:tokenB的储备量
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        // 获取收取手续费的地址
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        // 节省gas
        uint _kLast = kLast;
        if (feeOn) {
            if (_kLast != 0) {
                // rootk=sqrt(_reserve0 * _reserve1)
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                // 上一次交易后的sqrt(k)值
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    // 分子(lptoken总量*(rootK-rootKLast))
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    // 分母(rooL*5+rooKLast)
                    uint denominator = rootK.mul(5).add(rootKLast);
                    // liquidity = ( totalSupply * ( sqrt(_reserve0 * _reserve1) -  sqrt(_kLast) ) ) / sqrt(_reserve0 * _reserve1) * 5 + sqrt(_kLast)
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // 铸造lptoken   添加流动性调用该函数
    // 参数：to:接受lptoken的地址
    // 五步：获取添加流动性后的两个token的数量 --> 计算实际转入的代币数量 --> 计算Lptoken --> 转移lptoken --> 更新储备量
    function mint(address to) external lock returns (uint liquidity) {
        //  节省gas。获取当前储备量(reserve0, reserve1) 和 上一次更新储备量的时间间隔
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        // 1.获取添加流动性后的两个token的数量
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        // 2.计算实际转入的代币数量
        uint amount0 = balance0.sub(_reserve0);   // amount0 = balance0 - _reserve0
        uint amount1 = balance1.sub(_reserve1);   // amount1 = balance1 - _reserve1
        // 判断是否进行收取手续费
        bool feeOn = _mintFee(_reserve0, _reserve1);
        // 节省gas，必须在这里定义，因为totalSupply可以在_mintFee中更新
        uint _totalSupply = totalSupply;
        // 3.创建一个新的流动性池，首次铸造​：当池子是空的时候，第一次添加流动性会永久锁定最小流动性(MINIMUM_LIQUIDITY)
        // 假如第一次存入1001tokenA和1001tokenB,获取的1 lp。第二次用户投入10000TokenA和10000tokenB呢，得到多少Lp
        //   K = sqrt(1001*1001) = 1001，Lp1 = 1001-1000 = 1，那么 totalSupply = 1000+1 ；
        //   LP2 = min(10000*1001/1001, 10000*1001/1001) = 10000
        //   有1000流动性被销毁，所以LP1占池子份额 1 / (10000+1) 。  LP2占池子份额 10000 / (10000+1) ≈ 0.99990001
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            // 永久锁定MINIMUM_LIQUIDITY
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // 添加流动性所获得的lptoken数量(进行添加流动性的两种token的数量*目前lptoken的数量/当前token的储备量-->取较小值)
            // lp转 / token转 = lp总量 / token数量 
            // 为什么要选 min呢：用户A 10tokenA和10tokenB，流动性1001*10/1001=10，用户B 10tokenA和20tokenB，流动性1001*10/1001=10，
            // 用户B多花了10tokenB，但是获得的流动性还是10。我想说的是：min是为了规定用户按照规定比例添加代币对，多添加会造成损失。
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        // 4.铸造lptoken函数
        _mint(to, liquidity);
        //5. 更新储备函数
        _update(balance0, balance1, _reserve0, _reserve1);
        // 如果收取手续费，更新交易后的k值
        if (feeOn) kLast = uint(reserve0).mul(reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // 销毁lptoken退出流动性  ==  移除流动性
    // 参数：to:接受交易对返回token的地址
    // 五步：获取移除流动性后的两个token的数量 --> 计算出要转出token数量 --> 销毁lptoken --> 转出token --> 更新储备量
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        // 节省gas
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); 
        address _token0 = token0; 
        address _token1 = token1; 
        // 1.获取移除流动性后的两个token的数量
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        // 为什么用addres(this)?-->因为获取退出lptoken数量时，用户先将lptoken授权给router，然后token合约检查权限，
        //   然后router将获得额度的lptoken转给Pair合约地址(所以Lptoken合约有关于pair地址的存款记录)。所以用address(this)来获取用户的lptoken余额。
        uint liquidity = balanceOf[address(this)];
        // 收取手续费
        bool feeOn = _mintFee(_reserve0, _reserve1);
        // 节省gas，必须在这里定义，因为totalSupply可以在_mintFee中更新
        uint _totalSupply = totalSupply; 
        // 2.使用余额确保按比例分配-->(持有lptoken/总lptoken)*合约中持有token的数量
        // amount转 / lp销 = token余 / lp余
        amount0 = liquidity.mul(balance0) / _totalSupply; 
        amount1 = liquidity.mul(balance1) / _totalSupply; 
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        // 3.销毁lptoken
        _burn(address(this), liquidity);
        // 4.转账两种token
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        //5. 更新储备量函数
        _update(balance0, balance1, _reserve0, _reserve1);
         // 如果收取手续费，更新交易后的k值
        if (feeOn) kLast = uint(reserve0).mul(reserve1); 
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // 根据tokenA的数量在交易池中进行交换tokenB
    // 参数：amount0Out:to地址接受tokenA的数量  ：用户希望从池子中提取的 token0 数量。，amount1Out:to地址接受tokenB的数量  ：用户希望从池子中提取的 token1 数量。，to:接受token交换的地址，data:是否进行回调其他方法
    // 两步：转移token --> 更新储备量
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        // 希望从池子提取token不能同时为0，也必定有一个为0，一个不为0
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        // 节省gas，获取当前储备量(reserve0, reserve1) 和 上一次更新储备量的时间间隔
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        // 你要兑换的数量不能大于储备量，简意：判断池子必须有足够的流动性
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');
        uint balance0;
        uint balance1;
        {
            // _token{0,1}的作用域，避免堆栈过深的错误
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
            // 转移代币
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); 
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); 
            // 用于回调合约来实现一些特定的业务逻辑或其他自定义功能(闪电贷....)
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            // 合约拥有两种token的数量， 转移token0/token1后，池子中有两个代币的数量
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        // 进行兑换的token量
        // 获得合约两种token的数量，前提是(balance > _reserve - amountOut)，就是当前合约拥有的token数量应该是大于(储备值-输出到to地址的值)，返回之间的差值
        // 按理说amount0In == amount0Out  那为什么需要还要计算一边amount0In呢？
        // 因为怕 试图通过伪造同时输出来操纵价格，这个也称攻击向量
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        // 投入金额不足
        // 手续费
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        {
            // Adjusted{0,1}的作用域，避免堆栈过深的错误
            // balanceAdjusted = balance * 1000 - amountIn * 3(确保在计算余额调整后的值时不会因为小数精度问题而导致错误)
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            // 确保在交易完成后，资金池的储备量满足 Uniswap V2 中的 K 恒定公式，即 K = _reserve0 * _reserve1
            require(
                // balance0Adjusted * balance1Adjusted >= _reserve0 * _reserve0 * 1000 ** 2
                balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000 ** 2),
                'UniswapV2: K'
            );
        }
        // 更新储备量函数
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // 使两个token的余额与储备相等
    // 参数：to:接受两个token的余额与储备之间差值的地址
    function skim(address to) external lock {
        // 节省汽油
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // 使两个token的储备与余额相匹配
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}
