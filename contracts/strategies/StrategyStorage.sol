//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IController.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/SafeMath.sol";

contract StrategyStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public controller;
    address public governance;
    address public strategist;
    
    uint256 public _performanceFee = 450;
    uint256 public _strategistReward = 50;
    uint256 public _withdrawalFee = 50;
    uint256 public _harvesterReward = 30;
    uint256 internal _withdrawalMax = 10000;
    uint256 public constant FEE_DENOMINATOR = 10000;

    uint256 public targetBorrowLimit;
    uint256 public targetBorrowLimitHysteresis;

    bool public paused;

    modifier onlyController {
        require(msg.sender == controller, "!controller");
        _;
    }

    modifier onlyGovernance {
        require(msg.sender == controller, "!governance");
        _;
    }

    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    function setController(address _controller) external onlyGovernance {
        controller = _controller;
    }

    function setStrategist(address _strategist) external onlyGovernance {
        strategist = _strategist;
    }

    function setPerformanceFee(uint256 performanceFee) external onlyGovernance {
        require(msg.sender == governance, "!governance");
        _performanceFee = performanceFee;
    }

    function setStrategistReward(uint256 strategistReward) external onlyGovernance {
        require(msg.sender == governance, "!governance");
        _strategistReward = strategistReward;
    }

    function setWithdrawalFee(uint256 withdrawalFee) external onlyGovernance {
        require(msg.sender == governance, "!governance");
        _withdrawalFee = withdrawalFee;
    }

    function setHarvesterReward(uint256 harvesterReward) external onlyGovernance {
        require(msg.sender == governance, "!governance");
        _harvesterReward = harvesterReward;
    }

    function setTargetBorrowLimit(uint256 _targetBorrowLimit, uint256 _targetBorrowLimitHysteresis) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        targetBorrowLimit = _targetBorrowLimit;
        targetBorrowLimitHysteresis = _targetBorrowLimitHysteresis;
    }

    function vaults(address underlying) public view returns (address) {
        return IController(controller).vaults(underlying);
    }

    function getFee(uint amount) public view returns (uint) {
        return amount.mul(_withdrawalFee).div(FEE_DENOMINATOR);
    }

    function _sendToVaultWithFee(address underlying, uint amount) internal {
        uint256 _fee = getFee(amount);
        IERC20(underlying).safeTransfer(IController(controller).rewards(), _fee);

        _sendToVault(underlying, amount.sub(_fee));
    }

    function _sendToVault(address underlying, uint amount) internal {
        address vault = vaults(underlying);
        require(vault != address(0), "Not a vault!");
        IERC20(underlying).safeTransfer(vault, amount);
    }
}
