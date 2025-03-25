// SPDX-License-Identifier: MIT

/*
$HOG is the primary token of the Hand of God protocol, designed to function as a medium of exchange while maintaining a soft peg to $OS.
*/

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@shared/interfaces/IOracle.sol";
import "@shared/interfaces/IOperator.sol";
import "./owner/Operator.sol";
import "./lib/SafeMath8.sol";

contract HOG is ERC20, Operator, ReentrancyGuard {
    using SafeMath8 for uint8;
    using SafeMath for uint256;

    uint256 public constant INITIAL_DAOFUND_DISTRIBUTION = 1000 ether; // 1000 HOG
    uint256 public constant GENESIS_DISTRIBUTION = 714000 ether; // 714k HOG for genesis pool

    bool public rewardsDistributed = false;

    // Oracle
    address public hogOracle;

    // Tax configuration
    uint256 public constant TAX_DENOMINATOR = 10000;
    uint256 public constant TAX_CEILING_1 = 13000; // 1.3
    uint256 public constant TAX_CEILING_2 = 12000; // 1.2
    uint256 public constant TAX_CEILING_3 = 11000; // 1.1
    uint256 public constant TAX_CEILING_4 = 10000; // 1.0

    // Tax rates (now adjustable by operator)
    uint256 public taxRate1 = 500;  // 5%
    uint256 public taxRate2 = 1200; // 12%
    uint256 public taxRate3 = 1800; // 18%
    uint256 public taxRate4 = 2500; // 25%
    uint256 public taxRate5 = 4000; // 40%

    // Tax recipient
    address public taxRecipient;

    // Events
    event TaxCollected(address indexed from, address indexed to, uint256 amount, uint256 taxRate);
    event TaxRateUpdated(uint256 indexed rateIndex, uint256 oldRate, uint256 newRate);
    event TaxRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event HogOracleUpdated(address indexed oldOracle, address indexed newOracle);

    /**
     * @notice Constructs the HOG ERC-20 contract.
     * @param _hogOracle The address of the HOG price oracle
     * @param _taxRecipient The address that will receive collected taxes
     */
    constructor(address _hogOracle, address _taxRecipient) ERC20("HOG", "HOG") {
        require(_hogOracle != address(0), "Oracle address cannot be zero");
        require(_taxRecipient != address(0), "Tax recipient cannot be zero");
        hogOracle = _hogOracle;
        taxRecipient = _taxRecipient;
        _mint(msg.sender, 200 ether);
    }

    /**
     * @notice Fetches the current HOG price from the oracle
     * @return _hogPrice The current price of HOG
     */
    function _getHogPrice() internal view returns (uint256 _hogPrice) {
        try IOracle(hogOracle).consult(address(this), 1e18) returns (uint256 _price) {
            return uint256(_price);
        } catch {
            revert("Hog: failed to fetch HOG price from Oracle");
        }
    }

    /**
     * @notice Updates the HOG price oracle address
     * @param hogOracle_ The new oracle address
     */
    function setHogOracle(address hogOracle_) public onlyOperator {
        require(hogOracle_ != address(0), "Oracle address cannot be zero");
        address oldOracle = hogOracle;
        hogOracle = hogOracle_;
        emit HogOracleUpdated(oldOracle, hogOracle_);
    }

    /**
     * @notice Updates the tax recipient address
     * @param taxRecipient_ The new tax recipient address
     */
    function setTaxRecipient(address taxRecipient_) public onlyOperator {
        require(taxRecipient_ != address(0), "Tax recipient cannot be zero");
        address oldRecipient = taxRecipient;
        taxRecipient = taxRecipient_;
        emit TaxRecipientUpdated(oldRecipient, taxRecipient_);
    }

    /**
     * @notice Updates a specific tax rate
     * @param rateIndex The index of the tax rate to update (1-5)
     * @param newRate The new tax rate (in basis points, e.g., 500 for 5%)
     */
    function updateTaxRate(uint256 rateIndex, uint256 newRate) public onlyOperator {
        require(newRate <= TAX_DENOMINATOR, "Tax rate cannot exceed 100%");
        require(rateIndex >= 1 && rateIndex <= 5, "Invalid rate index");

        uint256 oldRate;
        if (rateIndex == 1) {
            oldRate = taxRate1;
            taxRate1 = newRate;
        } else if (rateIndex == 2) {
            oldRate = taxRate2;
            taxRate2 = newRate;
        } else if (rateIndex == 3) {
            oldRate = taxRate3;
            taxRate3 = newRate;
        } else if (rateIndex == 4) {
            oldRate = taxRate4;
            taxRate4 = newRate;
        } else {
            oldRate = taxRate5;
            taxRate5 = newRate;
        }

        emit TaxRateUpdated(rateIndex, oldRate, newRate);
    }

    /**
     * @notice Gets the current tax rate based on the HOG price
     * @return The current tax rate in basis points
     */
    function getTaxRate() public view returns (uint256) {
        uint256 currentPrice = _getHogPrice();
        
        if (currentPrice >= TAX_CEILING_1) return taxRate1;
        if (currentPrice >= TAX_CEILING_2) return taxRate2;
        if (currentPrice >= TAX_CEILING_3) return taxRate3;
        if (currentPrice >= TAX_CEILING_4) return taxRate4;
        return taxRate5;
    }

    /**
     * @notice Override the _transfer function to implement the tax mechanism
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param amount The amount to transfer
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override nonReentrant {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 taxRate = getTaxRate();
        uint256 taxAmount = amount.mul(taxRate).div(TAX_DENOMINATOR);
        uint256 transferAmount = amount.sub(taxAmount);

        super._transfer(from, to, transferAmount);
        
        if (taxAmount > 0) {
            super._transfer(from, taxRecipient, taxAmount);
            emit TaxCollected(from, to, amount, taxRate);
        }
    }

    /**
     * @notice Operator mints HOG to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of HOG to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    /**
     * @notice Burns tokens from the caller's balance
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /**
     * @notice Burns tokens from a specified address
     * @param account The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public onlyOperator {
        _burn(account, amount);
    }

    /**
     * @notice Transfers tokens from one address to another
     * @param sender The address to transfer from
     * @param recipient The address to transfer to
     * @param amount The amount to transfer
     * @return bool indicating success
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @notice distribute to reward pool (only once)
     * @param daoFund_ The address of the DAO fund
     * @param genesis_ The address of the genesis pool
     */
    function distributeReward(address daoFund_, address genesis_) external onlyOperator {
        require(daoFund_ != address(0), "!_treasury");
        require(genesis_ != address(0), "!_genesis");
        require(!rewardsDistributed, "only can distribute once");
        rewardsDistributed = true;
        _mint(daoFund_, INITIAL_DAOFUND_DISTRIBUTION);
        _mint(genesis_, GENESIS_DISTRIBUTION);
    }

    /**
     * @notice Recovers unsupported tokens that were sent to the contract
     * @param token_ The token to recover
     * @param amount_ The amount to recover
     * @param to_ The address to send the tokens to
     */
    function governanceRecoverUnsupported(IERC20 token_, uint256 amount_, address to_) external onlyOperator {
        require(to_ != address(0), "Recipient cannot be zero address");
        require(token_.transfer(to_, amount_), "Transfer failed");
    }
}
