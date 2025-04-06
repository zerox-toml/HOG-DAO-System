deploy-sepolia:
	forge create contracts/Treasury.sol:Treasury --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_URL --broadcast --constructor-args $HOG_ADDRESS

deploy-sepolia-script:
	forge script script/Treasury.s.sol:DeployTreasury --rpc-url $SEPOLIA_URL --broadcast --private-key $PRIVATE_KEY

verify-sepolia:
	forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address)" 0xa54b32E8432d5908c2f44e88d54Ba52835e7377b) \
    --etherscan-api-key 6XJ6B1342MD2S4H1H3HTPVJ7Y2BZ6J7269 \
    --compiler-version v0.8.19 \
    0x9ba3858B6cFfD38EC6b293C43C83D531729759B5 \
    contracts/Treasury.sol:Treasury

