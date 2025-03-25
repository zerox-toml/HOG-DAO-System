// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/HOG.sol";
import "@shared/interfaces/IOracle.sol";

contract MockOracle is IOracle {
    uint256 private price;

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut) {
        return price * amountIn / 1e18;
    }

    function twap(address token, uint256 amountIn) external view returns (uint256 amountOut) {
        return price * amountIn / 1e18;
    }

    function update() external {}
}

contract HOGTest is Test {
    HOG public hog;
    MockOracle public oracle;
    address public constant OPERATOR = address(0xABC);
    address public constant USER1 = address(0x456);
    address public constant USER2 = address(0x789);
    address public constant TAX_RECIPIENT = address(0x123);

    function setUp() public {
        oracle = new MockOracle();
        hog = new HOG(address(oracle), TAX_RECIPIENT);
        
        // Transfer operator role
        hog.transferOperator(OPERATOR);
        
        // Mint initial tokens to USER1 for testing
        vm.prank(OPERATOR);
        hog.mint(USER1, 1000 ether);
    }

    function testInitialState() public {
        assertEq(hog.name(), "HOG");
        assertEq(hog.symbol(), "HOG");
        assertEq(hog.operator(), OPERATOR);
        assertEq(hog.hogOracle(), address(oracle));
        assertEq(hog.taxRecipient(), TAX_RECIPIENT);
        assertEq(hog.balanceOf(USER1), 1000 ether);
        assertEq(hog.rewardsDistributed(), false);
    }

    function testTaxRates() public {
        assertEq(hog.taxRate1(), 500);  // 5%
        assertEq(hog.taxRate2(), 1200); // 12%
        assertEq(hog.taxRate3(), 1800); // 18%
        assertEq(hog.taxRate4(), 2500); // 25%
        assertEq(hog.taxRate5(), 4000); // 40%
    }

    function testTaxCalculation() public {
        uint256 amount = 100 ether;
        
        // Set price to trigger different tax rates
        oracle.setPrice(13000); // Above TAX_CEILING_1
        uint256 taxRate1 = hog.getTaxRate();
        assertEq(taxRate1, hog.taxRate1());
        
        oracle.setPrice(12000); // Above TAX_CEILING_2
        uint256 taxRate2 = hog.getTaxRate();
        assertEq(taxRate2, hog.taxRate2());
        
        oracle.setPrice(11000); // Above TAX_CEILING_3
        uint256 taxRate3 = hog.getTaxRate();
        assertEq(taxRate3, hog.taxRate3());
        
        oracle.setPrice(10000); // Above TAX_CEILING_4
        uint256 taxRate4 = hog.getTaxRate();
        assertEq(taxRate4, hog.taxRate4());
        
        oracle.setPrice(9000); // Below TAX_CEILING_4
        uint256 taxRate5 = hog.getTaxRate();
        assertEq(taxRate5, hog.taxRate5());
    }

    function testTransferWithTax() public {
        uint256 amount = 100 ether;
        uint256 taxRate = hog.getTaxRate();
        uint256 taxAmount = amount * taxRate / hog.TAX_DENOMINATOR();
        uint256 transferAmount = amount - taxAmount;
        
        vm.prank(USER1);
        hog.transfer(USER2, amount);
        
        assertEq(hog.balanceOf(USER2), transferAmount);
        assertEq(hog.balanceOf(TAX_RECIPIENT), taxAmount);
        assertEq(hog.balanceOf(USER1), 1000 ether - amount);
    }

    function test_RevertWhen_TransferInsufficientBalance() public {
        uint256 amount = 2000 ether;
        
        vm.prank(USER1);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        hog.transfer(USER2, amount);
    }

    function test_RevertWhen_TransferZeroAddress() public {
        uint256 amount = 100 ether;
        
        vm.prank(USER1);
        vm.expectRevert("ERC20: transfer to the zero address");
        hog.transfer(address(0), amount);
    }

    function testMint() public {
        uint256 amount = 100 ether;
        
        vm.prank(OPERATOR);
        bool success = hog.mint(USER2, amount);
        
        assertTrue(success);
        assertEq(hog.balanceOf(USER2), amount);
    }

    function test_RevertWhen_MintNonOperator() public {
        uint256 amount = 100 ether;
        
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        hog.mint(USER2, amount);
    }

    function testBurn() public {
        uint256 amount = 100 ether;
        
        vm.prank(USER1);
        hog.burn(amount);
        
        assertEq(hog.balanceOf(USER1), 900 ether);
    }

    function testBurnFrom() public {
        uint256 amount = 100 ether;
        
        vm.prank(OPERATOR);
        hog.burnFrom(USER1, amount);
        
        assertEq(hog.balanceOf(USER1), 900 ether);
    }

    function test_RevertWhen_BurnFromNonOperator() public {
        uint256 amount = 100 ether;
        
        vm.prank(USER2);
        vm.expectRevert("operator: caller is not the operator");
        hog.burnFrom(USER1, amount);
    }

    function test_RevertWhen_BurnFromInsufficientBalance() public {
        uint256 amount = 2000 ether;
        
        vm.prank(OPERATOR);
        vm.expectRevert("ERC20: burn amount exceeds balance");
        hog.burnFrom(USER1, amount);
    }

    function testDistributeReward() public {
        address daoFund = address(0x111);
        address genesis = address(0x222);
        
        vm.prank(OPERATOR);
        hog.distributeReward(daoFund, genesis);
        
        assertEq(hog.balanceOf(daoFund), hog.INITIAL_DAOFUND_DISTRIBUTION());
        assertEq(hog.balanceOf(genesis), hog.GENESIS_DISTRIBUTION());
        assertTrue(hog.rewardsDistributed());
    }

    function test_RevertWhen_DistributeRewardNonOperator() public {
        address daoFund = address(0x111);
        address genesis = address(0x222);
        
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        hog.distributeReward(daoFund, genesis);
    }

    function test_RevertWhen_DistributeRewardTwice() public {
        address daoFund = address(0x111);
        address genesis = address(0x222);
        
        vm.prank(OPERATOR);
        hog.distributeReward(daoFund, genesis);
        
        vm.prank(OPERATOR);
        vm.expectRevert("only can distribute once");
        hog.distributeReward(daoFund, genesis);
    }

    function test_RevertWhen_DistributeRewardZeroAddress() public {
        address daoFund = address(0);
        address genesis = address(0x222);
        
        vm.prank(OPERATOR);
        vm.expectRevert("!_treasury");
        hog.distributeReward(daoFund, genesis);
    }

    function testSetHogOracle() public {
        address newOracle = address(0x999);
        
        vm.prank(OPERATOR);
        hog.setHogOracle(newOracle);
        
        assertEq(hog.hogOracle(), newOracle);
    }

    function test_RevertWhen_SetHogOracleNonOperator() public {
        address newOracle = address(0x999);
        
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        hog.setHogOracle(newOracle);
    }

    function test_RevertWhen_SetHogOracleZeroAddress() public {
        vm.prank(OPERATOR);
        vm.expectRevert("Oracle address cannot be zero");
        hog.setHogOracle(address(0));
    }

    function testSetTaxRecipient() public {
        address newRecipient = address(0x888);
        
        vm.prank(OPERATOR);
        hog.setTaxRecipient(newRecipient);
        
        assertEq(hog.taxRecipient(), newRecipient);
    }

    function test_RevertWhen_SetTaxRecipientNonOperator() public {
        address newRecipient = address(0x888);
        
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        hog.setTaxRecipient(newRecipient);
    }

    function test_RevertWhen_SetTaxRecipientZeroAddress() public {
        vm.prank(OPERATOR);
        vm.expectRevert("Tax recipient cannot be zero");
        hog.setTaxRecipient(address(0));
    }

    function testUpdateTaxRate() public {
        uint256 newRate = 1000; // 10%
        
        vm.prank(OPERATOR);
        hog.updateTaxRate(1, newRate);
        
        assertEq(hog.taxRate1(), newRate);
    }

    function test_RevertWhen_UpdateTaxRateNonOperator() public {
        uint256 newRate = 1000; // 10%
        
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        hog.updateTaxRate(1, newRate);
    }

    function test_RevertWhen_UpdateTaxRateInvalidIndex() public {
        uint256 newRate = 1000; // 10%
        
        vm.prank(OPERATOR);
        vm.expectRevert("Invalid rate index");
        hog.updateTaxRate(6, newRate);
    }

    function test_RevertWhen_UpdateTaxRateExceedsMax() public {
        uint256 newRate = 10001; // 100.01%
        
        vm.prank(OPERATOR);
        vm.expectRevert("Tax rate cannot exceed 100%");
        hog.updateTaxRate(1, newRate);
    }

    function testGovernanceRecoverUnsupported() public {
        // Create a mock token
        MockERC20 mockToken = new MockERC20("Mock", "MOCK");
        mockToken.mint(address(hog), 100 ether);
        
        vm.prank(OPERATOR);
        hog.governanceRecoverUnsupported(mockToken, 100 ether, USER1);
        
        assertEq(mockToken.balanceOf(USER1), 100 ether);
    }

    function test_RevertWhen_GovernanceRecoverUnsupportedNonOperator() public {
        MockERC20 mockToken = new MockERC20("Mock", "MOCK");
        mockToken.mint(address(hog), 100 ether);
        
        vm.prank(USER1);
        vm.expectRevert("operator: caller is not the operator");
        hog.governanceRecoverUnsupported(mockToken, 100 ether, USER1);
    }

    function test_RevertWhen_GovernanceRecoverUnsupportedZeroAddress() public {
        MockERC20 mockToken = new MockERC20("Mock", "MOCK");
        mockToken.mint(address(hog), 100 ether);
        
        vm.prank(OPERATOR);
        vm.expectRevert("Recipient cannot be zero address");
        hog.governanceRecoverUnsupported(mockToken, 100 ether, address(0));
    }
}

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
} 