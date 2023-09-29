// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StringSplitter {
    function splitString(
        string memory input,
        string memory delimiter
    ) public pure returns (string[] memory) {
        bytes memory inputBytes = bytes(input);
        bytes memory delimiterBytes = bytes(delimiter);

        uint256 delimiterCount = 1;

        // Count the number of delimiters in the input string
        for (uint256 i = 0; i < inputBytes.length; i++) {
            if (isEqual(inputBytes, i, delimiterBytes)) {
                delimiterCount++;
            }
        }

        string[] memory parts = new string[](delimiterCount);
        uint256 partIndex = 0;

        uint256 startIndex = 0;
        for (uint256 i = 0; i < inputBytes.length; i++) {
            if (isEqual(inputBytes, i, delimiterBytes)) {
                parts[partIndex] = substring(input, startIndex, i);
                startIndex = i + delimiterBytes.length;
                partIndex++;
            }
        }

        // Add the last part of the string
        parts[partIndex] = substring(input, startIndex, inputBytes.length);

        return parts;
    }

    function isEqual(
        bytes memory input,
        uint256 startPos,
        bytes memory delimiter
    ) private pure returns (bool) {
        for (uint256 i = 0; i < delimiter.length; i++) {
            if (input[startPos + i] != delimiter[i]) {
                return false;
            }
        }

        return true;
    }

    function substring(
        string memory input,
        uint256 startPos,
        uint256 endPos
    ) private pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        bytes memory result = new bytes(endPos - startPos);

        for (uint256 i = startPos; i < endPos; i++) {
            result[i - startPos] = inputBytes[i];
        }

        return string(result);
    }
}
