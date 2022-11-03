// SPDX-License-Identifier: MIT
//pragma solidity ^0.8.0;
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

//import "hardhat/console.sol";

contract SaiOracle is Ownable {
    mapping(uint256 => string) private mapValue;
    mapping(uint256 => uint256) private mapIndex;

    uint256 public Degree;
    uint256 public MinKey;
    uint256 public MaxKey;

    uint256 constant MAX_KEY=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    constructor() {
        setIntervalDegree(32);
    }

    function setIntervalDegree(uint256 _Degree) public onlyOwner {
        require(_Degree > 0, "setInterval::Degree is zero");
        //require(_Degree <=32, "setInterval::Max Degree = 32");
        require(
            _Degree % 8 == 0,
            "setInterval::Degree of the interval must be a multiple of 8"
        );

        Degree = _Degree;
        MinKey = 1 << (Degree - 8);
        MaxKey = 1 << Degree;
    }

    function setKeyValue(uint256 key, string memory value) public {
        require(key >= MinKey, "setKeyValue::key is smaller than the MinKey");
        require(key < MaxKey, "setKeyValue::key is larger than the MaxKey");
        mapValue[key] = value;

        uint256 _Degree = Degree;

        while (_Degree > 0) {
            _Degree -= 8;

            uint256 bit = key & 0xFF;
            key = key >> 8;

            uint256 key0 = mapIndex[key];
            mapIndex[key] = key0 | (1 << bit);

            //console.log("setValue %s  key=%s _Degree=%s", value, key,_Degree);
            //console.logBytes32(bytes32(mapIndex[key]));
        }
    }

    function setValue(string memory value) public {
        setKeyValue(block.timestamp, value);
    }

    function getValue(uint256 key) public view returns (string memory) {
        return mapValue[key];
    }

    function findKeyLeft(uint256 key) internal view returns (uint256) {
        (, uint256 nKey) = findKeyLeftIter(key, key >> Degree, Degree);
        return nKey;
    }

    function findKeyLeftIter(
        uint256 key,
        uint256 keyIndex,
        uint256 _Degree
    ) internal view returns (bool, uint256) {
        uint256 bits = mapIndex[keyIndex];
        //console.log("findValue key=%s keyIndex=%s _Degree=%s", key, keyIndex,_Degree);
        //console.logBytes32(bytes32(bits));

        uint256 Degree2 = _Degree -= 8;
        uint256 nStart = (key >> Degree2) & 0xFF;
        uint256 nShift = 0xFF - nStart;
        bits = (bits << nShift) >> nShift;
        if (bits == 0) return (false, 0);

        //console.logBytes32(bytes32(bits));
        uint256 nKey = LeftBitToKey(bits);

        uint256 keyIndex2 = (keyIndex << 8) | nKey;

        if (Degree2 > 0) {
            if (nKey < nStart)
                key = MAX_KEY;

            (bool bFind, uint256 nKey2) = findKeyLeftIter(
                key,
                keyIndex2,
                Degree2
            );
            if (!bFind) {
                //consolelog("not find nKey=%s nStart=%s _Degree=%s",nKey,nStart,_Degree);
                if (nKey == nStart) {
                    //try restart search

                    //console.logBytes32(bytes32(bits));
                    nShift++;
                    bits = (bits << nShift) >> nShift;
                    //consolelogBytes32(bytes32(bits));
                    if (bits == 0) return (false, 0);
                    nKey = LeftBitToKey(bits);
                    keyIndex2 = (keyIndex << 8) | nKey;
                    (bFind, nKey2) = findKeyLeftIter(MAX_KEY, keyIndex2, Degree2);

                    if (!bFind) return (false, 0);
                    
                } else {
                    return (false, 0);
                }
            }

            keyIndex2 <<= Degree2;
            keyIndex2 |= nKey2;
        }
        return (true, keyIndex2);
    }

    function findValue(uint256 key) public view returns (string memory) {
        return mapValue[findKeyLeft(key)];
    }


    function LeftBitToKey(uint256 bits) internal pure returns (uint256) {
        uint256 nKey = 0;
        uint256 BitDelimiter = 128;

        while (BitDelimiter > 0) {
            uint256 bits2 = bits >> BitDelimiter;
            if (bits2 != 0) {
                bits = bits2;
                nKey += BitDelimiter;
            }

            BitDelimiter >>= 1;
        }
        return nKey;
    }

    function RightBitToKey(uint256 bits) internal pure returns (uint256) {
        uint256 nKey = 0;
        uint256 BitDelimiter = 128;
        uint256 BitMaska = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        while (BitDelimiter > 0) {
            if (bits & BitMaska == 0) {
                bits >>= BitDelimiter;
                nKey += BitDelimiter;
            }

            BitDelimiter >>= 1;
            BitMaska >>= BitDelimiter;
        }
        return nKey;
    }

    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function doFindValue(uint256 key) external {
        //string memory Str = 
        findValue(key);
        findValue(key);
        //console.log("Find : %s",Str);
        //uint256 bits=0x0100000000000000000000000000000010000000000000000000000001000000;
        //console.log("FindL: %s",LeftBitToKey(bits));
    }

}
