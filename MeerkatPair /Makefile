deploy-meerkat-pair:
	forge create --broadcast --rpc-url $SEPOLIA_URL --account baseman contracts/MeerkatPair.sol:MeerkatPair --constructor-args $HOG_ADDRESS $WETH_ADDRESS
# 0xb3834C923C34e5316809C3234b4129d316a1Ccf2

verify-meerkat-pair:
	forge verify-contract 0xb3834C923C34e5316809C3234b4129d316a1Ccf2 contracts/MeerkatPair.sol:MeerkatPair --constructor-args $(cast abi-encode "constructor(address,address)" 0xb3B1fBEE53732174fE9Eca63d76660CA40974d55 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9) --chain-id 11155111 --watch

deploy-meerkat-pair-ghog:
	forge create --broadcast --rpc-url $SEPOLIA_URL --account baseman contracts/MeerkatPair.sol:MeerkatPair --constructor-args $GHOG_ADDRESS $WETH_ADDRESS
# 0x4E3C43FF6F216333A94B7ea865AE57bDe504CF72

verify-meerkat-pair-ghog:
	forge verify-contract 0x4E3C43FF6F216333A94B7ea865AE57bDe504CF72 contracts/MeerkatPair.sol:MeerkatPair --constructor-args $(cast abi-encode "constructor(address,address)" 0xE69A8A6cD11D46BE328F4d6b211032f836f89743 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9) --chain-id 11155111 --watch