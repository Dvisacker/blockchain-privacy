pragma solidity ^0.4.19;

import "./verifier.sol";

contract Mixer is Verifier {
    mapping (bytes32 => bool) public roots;

    struct MerkleTree {
        uint currentLeafIndex;
        uint[16] leaves;
    }

    MerkleTree public tree;

    function Mixer() {
        tree.currentLeafIndex = 0;
        for (uint i = 0; i < 16; i++) {
            tree.leaves[i] = 0x0;
        }
    }

    // MerkleTree.append(commitment)
    function insert(uint numberToFactorize) returns (bool res) {
        if (tree.currentLeafIndex == 16) {
            return false;
        }
        tree.leaves[tree.currentLeafIndex] = numberToFactorize;
        tree.currentLeafIndex++;
        return true;
    }

    function getLeaves() constant returns (uint[16]) {
        return tree.leaves;
    }

    function getTree() constant returns (bytes32[32] currentTree) {
        // bytes32[32] memory currentTree;
        uint i;
        for (i = 0; i < 16; i++) {
            currentTree[16 + i] = sha256(tree.leaves[i]);
        }

        for (i = 16 - 1; i > 0; i--) {
            currentTree[i] = sha256(currentTree[i*2], currentTree[i*2+1]);
        }

        return currentTree;
    }

    // MerkleTree.root()
    function getRoot() constant returns(bytes32 root) {
        root = getTree()[1];
    }
    
    function isElementOfArray(uint element, uint[16] array) returns (bool) {
        bool find = false;
        uint arrayLength = array.length;

        for (uint i=0; i < arrayLength; i++) {
            if (array[i] == element) {
                find = true;
            }
        }
        return find;
    }

    function deposit(uint numberToFactorize) returns (bool res) {
        if (msg.value != 1 ether) {
            msg.sender.send(msg.value);
            return false;
        }
        if (!insert(numberToFactorize)) {
            msg.sender.send(msg.value);
            return false;
        }
        bytes32 rootTree = getRoot();
        roots[rootTree] = true;
        return true;
    }

    function withdraw(
        bytes32 rootTree,
        uint[2] a,
        uint[2] a_p,
        uint[2][2] b,
        uint[2] b_p,
        uint[2] c,
        uint[2] c_p,
        uint[2] h,
        uint[2] k,
        uint[2] input
    ) returns (bool) {
        uint[16] memory leaves = getLeaves();
        // Verify that we provide a proof for an element in the array
        bool find = isElementOfArray(input[0], leaves);
        if (roots[rootTree] == true && find) {
            if (!verifyTx(a, a_p, b, b_p, c, c_p, h, k, input)) {
                return false;
            }
            if (!msg.sender.send(1 ether)) {
                throw;
            } else {
                return true;
            }
        } else {
             return false;
        }
    }
}
