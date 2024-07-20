**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [weak-prng](#weak-prng) (1 results) (High)
 - [name-reused](#name-reused) (1 results) (High)
 - [reentrancy-no-eth](#reentrancy-no-eth) (1 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (2 results) (Medium)
 - [events-maths](#events-maths) (1 results) (Low)
 - [missing-zero-check](#missing-zero-check) (1 results) (Low)
 - [calls-loop](#calls-loop) (10 results) (Low)
 - [reentrancy-events](#reentrancy-events) (1 results) (Low)
 - [timestamp](#timestamp) (2 results) (Low)
 - [void-cst](#void-cst) (1 results) (Low)
 - [solc-version](#solc-version) (5 results) (Informational)
 - [missing-inheritance](#missing-inheritance) (3 results) (Informational)
 - [naming-convention](#naming-convention) (20 results) (Informational)
 - [unused-state](#unused-state) (1 results) (Informational)
 - [constable-states](#constable-states) (3 results) (Optimization)
## weak-prng
Impact: High
Confidence: Medium
 - [ ] ID-0
[Merging._selectResultArr(uint256[])](src/Merging.sol#L242-L276) uses a weak PRNG: "[randomNum = uint256(keccak256(bytes)(abi.encodePacked(block.timestamp,msg.sender,block.prevrandao))) % 100](src/Merging.sol#L244)" 

src/Merging.sol#L242-L276


## name-reused
Impact: High
Confidence: High
 - [ ] ID-1
IERC721Crystal is re-used:
	- [IERC721Crystal](src/Merging.sol#L8-L18)
	- [IERC721Crystal](src/Staking.sol#L12-L20)

src/Merging.sol#L8-L18


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-2
Reentrancy in [ElementStake.unstake(uint24,uint256[])](src/Staking.sol#L98-L127):
	External calls:
	- [_rewardCount = claimReward(msg.sender,_elementId)](src/Staking.sol#L117)
		- [rewardToken.mintBaseElements(staker,rewardCount,rewardElement)](src/Staking.sol#L134)
	State variables written after the call(s):
	- [_stakeInfo.userStakedTokensCount -= tokensCount](src/Staking.sol#L120)
	[ElementStake.stakeInfo](src/Staking.sol#L48) can be used in cross function reentrancies:
	- [ElementStake.calculateReward(address,uint24)](src/Staking.sol#L139-L160)
	- [ElementStake.claimReward(address,uint24)](src/Staking.sol#L129-L136)
	- [ElementStake.stakeInfo](src/Staking.sol#L48)
	- [_stakingPool.stakedElementsCount -= tokensCount](src/Staking.sol#L121)
	[ElementStake.stakingPool](src/Staking.sol#L49) can be used in cross function reentrancies:
	- [ElementStake.claimReward(address,uint24)](src/Staking.sol#L129-L136)
	- [ElementStake.setStakeMap(uint24[2][])](src/Staking.sol#L188-L198)
	- [ElementStake.stakingPool](src/Staking.sol#L49)

src/Staking.sol#L98-L127


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-3
[Merging.mergeVolatiles(uint256[],uint256[]).count](src/Merging.sol#L126) is a local variable never initialized

src/Merging.sol#L126


 - [ ] ID-4
[Merging.merge(uint256[]).count](src/Merging.sol#L75) is a local variable never initialized

src/Merging.sol#L75


## events-maths
Impact: Low
Confidence: Medium
 - [ ] ID-5
[ElementStake.updateReward(uint256,uint256,uint256,uint256,uint256)](src/Staking.sol#L173-L185) should emit an event for: 
	- [periodTime = _periodTime](src/Staking.sol#L180) 
	- [maxRewardCount = _maxRewardCount](src/Staking.sol#L184) 

src/Staking.sol#L173-L185


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-6
[ERC721Crystal.setExternalContracts(address,address)._mergeContract](src/ERC721Crystal.sol#L112) lacks a zero-check on :
		- [MERGE = _mergeContract](src/ERC721Crystal.sol#L116)

src/ERC721Crystal.sol#L112


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-7
[Merging.mergeVolatiles(uint256[],uint256[])](src/Merging.sol#L92-L140) has external calls inside a loop: [nftToken.mintCrystals(msg.sender,uint24(resultElements[i_scope_1]),1)](src/Merging.sol#L129)

src/Merging.sol#L92-L140


 - [ ] ID-8
[Merging.isMergeAllowed(uint256[])](src/Merging.sol#L172-L184) has external calls inside a loop: [elementId = nftToken.elementId(tokenIds[i])](src/Merging.sol#L174)

src/Merging.sol#L172-L184


 - [ ] ID-9
[ElementStake.stakeMult(uint24,uint256[])](src/Staking.sol#L64-L95) has external calls inside a loop: [nftToken.ownerOf(_cachedTokenId) != msg.sender](src/Staking.sol#L74)

src/Staking.sol#L64-L95


 - [ ] ID-10
[ERC721Crystal._beforeTokenTransfers(address,address,uint256,uint256)](src/ERC721Crystal.sol#L131-L133) has external calls inside a loop: [STAKE.isCrystalStaked(startTokenId)](src/ERC721Crystal.sol#L132)

src/ERC721Crystal.sol#L131-L133


 - [ ] ID-11
[ElementStake.unstake(uint24,uint256[])](src/Staking.sol#L98-L127) has external calls inside a loop: [nftToken.ownerOf(_cachedTokenId) != msg.sender](src/Staking.sol#L106)

src/Staking.sol#L98-L127


 - [ ] ID-12
[Merging.mergeVolatiles(uint256[],uint256[])](src/Merging.sol#L92-L140) has external calls inside a loop: [nftToken.ownerOf(crystalIds[i]) != msg.sender](src/Merging.sol#L101)

src/Merging.sol#L92-L140


 - [ ] ID-13
[ElementStake.unstake(uint24,uint256[])](src/Staking.sol#L98-L127) has external calls inside a loop: [nftToken.elementId(_cachedTokenId) != _elementId](src/Staking.sol#L107)

src/Staking.sol#L98-L127


 - [ ] ID-14
[Merging.mergeVolatiles(uint256[],uint256[])](src/Merging.sol#L92-L140) has external calls inside a loop: [elementId = nftToken.elementId(crystalIds[i])](src/Merging.sol#L103)

src/Merging.sol#L92-L140


 - [ ] ID-15
[Merging.merge(uint256[])](src/Merging.sol#L66-L89) has external calls inside a loop: [nftToken.mintCrystals(msg.sender,uint24(resultElements[i]),1)](src/Merging.sol#L78)

src/Merging.sol#L66-L89


 - [ ] ID-16
[ElementStake.stakeMult(uint24,uint256[])](src/Staking.sol#L64-L95) has external calls inside a loop: [nftToken.elementId(_cachedTokenId) != _elementId](src/Staking.sol#L75)

src/Staking.sol#L64-L95


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-17
Reentrancy in [ElementStake.claimReward(address,uint24)](src/Staking.sol#L129-L136):
	External calls:
	- [rewardToken.mintBaseElements(staker,rewardCount,rewardElement)](src/Staking.sol#L134)
	Event emitted after the call(s):
	- [ClaimReward(staker,rewardCount,rewardElement)](src/Staking.sol#L135)

src/Staking.sol#L129-L136


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-18
[ElementStake.calculateReward(address,uint24)](src/Staking.sol#L139-L160) uses timestamp for comparisons
	Dangerous comparisons:
	- [(block.timestamp - stakeData.lastStakeTime) >= periodTime](src/Staking.sol#L145)
	- [(block.timestamp - stakeData.lastClaimTime) >= periodTime](src/Staking.sol#L146)
	- [totalPeriods >= maxRewardCount](src/Staking.sol#L153)
	- [totalPeriods > userMaxReward](src/Staking.sol#L156)

src/Staking.sol#L139-L160


 - [ ] ID-19
[Merging._selectResultArr(uint256[])](src/Merging.sol#L242-L276) uses timestamp for comparisons
	Dangerous comparisons:
	- [randomNum < a](src/Merging.sol#L259)
	- [randomNum < (a + b)](src/Merging.sol#L261)

src/Merging.sol#L242-L276


## void-cst
Impact: Low
Confidence: High
 - [ ] ID-20
Void constructor called in [ERC1155Volatile.constructor(address,address)](src/ERC1155Volatile.sol#L26-L30):
	- [ERC1155()](src/ERC1155Volatile.sol#L26)

src/ERC1155Volatile.sol#L26-L30


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-21
Pragma version[0.8.19](src/Merging.sol#L2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.

src/Merging.sol#L2


 - [ ] ID-22
Pragma version[0.8.19](src/ERC1155Volatile.sol#L2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.

src/ERC1155Volatile.sol#L2


 - [ ] ID-23
solc-0.8.19 is not recommended for deployment

 - [ ] ID-24
Pragma version[0.8.19](src/ERC721Crystal.sol#L2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.

src/ERC721Crystal.sol#L2


 - [ ] ID-25
Pragma version[0.8.19](src/Staking.sol#L2) necessitates a version too recent to be trusted. Consider deploying with 0.8.18.

src/Staking.sol#L2


## missing-inheritance
Impact: Informational
Confidence: High
 - [ ] ID-26
[ERC1155Volatile](src/ERC1155Volatile.sol#L8-L63) should inherit from [IERC1155Volatiles](src/Merging.sol#L20-L22)

src/ERC1155Volatile.sol#L8-L63


 - [ ] ID-27
[ElementStake](src/Staking.sol#L29-L204) should inherit from [IStaking](src/ERC721Crystal.sol#L9-L11)

src/Staking.sol#L29-L204


 - [ ] ID-28
[ERC721Crystal](src/ERC721Crystal.sol#L17-L143) should inherit from [IERC721Crystal](src/Merging.sol#L8-L18)

src/ERC721Crystal.sol#L17-L143


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-29
Parameter [ElementStake.stakeMult(uint24,uint256[])._elementId](src/Staking.sol#L64) is not in mixedCase

src/Staking.sol#L64


 - [ ] ID-30
Variable [Merging.MergeMap](src/Merging.sol#L50) is not in mixedCase

src/Merging.sol#L50


 - [ ] ID-31
Parameter [ElementStake.updateReward(uint256,uint256,uint256,uint256,uint256)._baseRate](src/Staking.sol#L174) is not in mixedCase

src/Staking.sol#L174


 - [ ] ID-32
Parameter [ElementStake.updateReward(uint256,uint256,uint256,uint256,uint256)._periodTime](src/Staking.sol#L177) is not in mixedCase

src/Staking.sol#L177


 - [ ] ID-33
Variable [ERC721Crystal.MERGE](src/ERC721Crystal.sol#L21) is not in mixedCase

src/ERC721Crystal.sol#L21


 - [ ] ID-34
Parameter [ERC721Crystal.setExternalContracts(address,address)._stakeContract](src/ERC721Crystal.sol#L112) is not in mixedCase

src/ERC721Crystal.sol#L112


 - [ ] ID-35
Parameter [ERC721Crystal.mintCrystals(address,uint24,uint256)._elementId](src/ERC721Crystal.sol#L65) is not in mixedCase

src/ERC721Crystal.sol#L65


 - [ ] ID-36
Parameter [ElementStake.unstake(uint24,uint256[])._elementId](src/Staking.sol#L98) is not in mixedCase

src/Staking.sol#L98


 - [ ] ID-37
Parameter [ElementStake.setExternalContracts(address,address)._rewardToken](src/Staking.sol#L168) is not in mixedCase

src/Staking.sol#L168


 - [ ] ID-38
Variable [ERC721Crystal.STAKE](src/ERC721Crystal.sol#L20) is not in mixedCase

src/ERC721Crystal.sol#L20


 - [ ] ID-39
Parameter [ERC721Crystal.setExternalContracts(address,address)._mergeContract](src/ERC721Crystal.sol#L112) is not in mixedCase

src/ERC721Crystal.sol#L112


 - [ ] ID-40
Parameter [ElementStake.setExternalContracts(address,address)._nftToken](src/Staking.sol#L168) is not in mixedCase

src/Staking.sol#L168


 - [ ] ID-41
Parameter [ElementStake.updateReward(uint256,uint256,uint256,uint256,uint256)._km](src/Staking.sol#L176) is not in mixedCase

src/Staking.sol#L176


 - [ ] ID-42
Variable [ERC1155Volatile.ElementLife](src/ERC1155Volatile.sol#L12) is not in mixedCase

src/ERC1155Volatile.sol#L12


 - [ ] ID-43
Parameter [Merging.setTokensContract(address,address)._volatileToken](src/Merging.sol#L218) is not in mixedCase

src/Merging.sol#L218


 - [ ] ID-44
Parameter [ElementStake.updateReward(uint256,uint256,uint256,uint256,uint256)._baseRateMax](src/Staking.sol#L175) is not in mixedCase

src/Staking.sol#L175


 - [ ] ID-45
Parameter [ERC721Crystal.batchMintCrystals(uint24[],uint256[])._elementIds](src/ERC721Crystal.sol#L44) is not in mixedCase

src/ERC721Crystal.sol#L44


 - [ ] ID-46
Parameter [Merging.setTokensContract(address,address)._nftToken](src/Merging.sol#L218) is not in mixedCase

src/Merging.sol#L218


 - [ ] ID-47
Parameter [Merging.setMergeMap(uint256[][5][]).Elements](src/Merging.sol#L192) is not in mixedCase

src/Merging.sol#L192


 - [ ] ID-48
Parameter [ElementStake.updateReward(uint256,uint256,uint256,uint256,uint256)._maxRewardCount](src/Staking.sol#L178) is not in mixedCase

src/Staking.sol#L178


## unused-state
Impact: Informational
Confidence: High
 - [ ] ID-49
[ERC1155Volatile.ElementLife](src/ERC1155Volatile.sol#L12) is never used in [ERC1155Volatile](src/ERC1155Volatile.sol#L8-L63)

src/ERC1155Volatile.sol#L12


## constable-states
Impact: Optimization
Confidence: High
 - [ ] ID-50
[ERC1155Volatile.name](src/ERC1155Volatile.sol#L9) should be constant 

src/ERC1155Volatile.sol#L9


 - [ ] ID-51
[ERC1155Volatile.symbol](src/ERC1155Volatile.sol#L10) should be constant 

src/ERC1155Volatile.sol#L10


 - [ ] ID-52
[ERC1155Volatile.ElementLife](src/ERC1155Volatile.sol#L12) should be constant 

src/ERC1155Volatile.sol#L12


