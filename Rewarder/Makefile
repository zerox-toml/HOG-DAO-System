deploy-rewarder-sepolia:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/Rewarder.sol:Rewarder --constructor-args $GHOG_ADDRESS $HOG_ADDRESS 2000000 10000000000000000000000000000000000000
		--watch \
		--constructor-args $(cast abi-encode "constructor(address,address,uint256,uint256)" 0x008769eE2D69B2B7da69d04fD1dbD17CFC3353b3 0xa54b32E8432d5908c2f44e88d54Ba52835e7377b 20000 400000000) \
		--etherscan-api-key 6XJ6B1342MD2S4H1H3HTPVJ7Y2BZ6J7269 \
		--compiler-version v0.8.19 \
		0xAdAC2e8dD85B69fFC4423BC9112d660C154aF9D4 \
		contracts/Rewarder.sol:Rewarder	

	forge create contracts/Rewarder.sol:Rewarder --account baseman --rpc-url $SEPOLIA_URL --broadcast --constructor-args $REWARDS_TOKEN $STAKING_TOKEN 5 100