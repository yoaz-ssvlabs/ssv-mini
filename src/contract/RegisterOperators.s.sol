pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {SSVNetwork} from "src/SSVNetwork.sol";
import {ISSVOperators} from "src/interfaces/ISSVOperators.sol";
import {console2} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract RegisterOperators is Script {

  uint256 constant OPERATOR_FEE = 1_000_000_000; // 1 SSV (in smallest unit)
  uint64 constant MAX_OPERATOR_FEE = 76_528_650_000_000; // Maximum fee limit
  bool constant SET_AS_PRIVATE = false; // Whether to set operators as private

  SSVNetwork public ssvNetwork;

  function run(address ssvNetworkAddress) external {

    ssvNetwork = SSVNetwork(ssvNetworkAddress);

    string[] memory publicKeys = getOperatorPublicKeys();

    vm.startBroadcast();

    ssvNetwork.updateMaximumOperatorFee(MAX_OPERATOR_FEE);

    for (uint256 i = 0; i < publicKeys.length; i++) {
      uint64 id = ssvNetwork.registerOperator(
        bytes(publicKeys[i]),
        OPERATOR_FEE,
        SET_AS_PRIVATE
      );
       console2.log("Successfully registered operator ID:", id);
       console2.log("Public key:", publicKeys[i]);
    }

    vm.stopBroadcast();

  }


  function getOperatorPublicKeys() internal view returns (string[] memory) {
    string memory publicKeysFile = vm.envOr("OPERATOR_KEYS_FILE", string(""));

    // Read from JSON file
    string memory json = vm.readFile(publicKeysFile);
    string[] memory keys = stdJson.readStringArray(json, "$.publicKeys");
    return keys;
  }
}
