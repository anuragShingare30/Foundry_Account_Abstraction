// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "lib/account-abstraction/contracts/utils/Exec.sol";

contract BaseAccount is IAccount,Ownable  {
    ////////////////////////////////
    // ERRORS //
    ////////////////////////////////
    error BasicAccount_NotFromEntryPoint();
    error BasicAccount_NotFromEntryPointOrOwner();
    error BaseAccount_CallFailedDuringExecute(bytes resultData);


    ////////////////////////////////
    // STATE VARIABLES //
    ////////////////////////////////
    uint256 constant SIGNATURE_VALIDATION_FAILED = 1;
    uint256 constant SIGNATURE_VALIDATION_SUCCESS = 0;
    IEntryPoint private immutable i_entryPoint;


    ////////////////////////////////
    // MODIFIERS //
    ////////////////////////////////
    modifier requireOnlyFromEntryPoint(){
        if(msg.sender != address(i_entryPoint)){
            revert BasicAccount_NotFromEntryPoint();
        }
        _;
    }
    modifier requireOnlyFromEntryPointOrOwner(){
        if(msg.sender != address(i_entryPoint) && msg.sender != owner()){
            revert BasicAccount_NotFromEntryPointOrOwner();
        }
        _;
    }

    ////////////////////////////////
    // FUNCTIONS //
    ////////////////////////////////

    constructor(address entryPoint) Ownable(msg.sender){
        i_entryPoint = IEntryPoint(entryPoint);
    }

    // To receive the funds
    receive() external payable {}

     /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     * signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
     * Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp              - The operation that is about to be executed.
     * @param userOpHash          - Hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds - Missing funds on the account's deposit in the entrypoint.
     *                              This is the minimum amount to transfer to the sender(entryPoint) to be
     *                              able to make the call. The excess is left as a deposit in the entrypoint
     *                              for future calls. Can be withdrawn anytime using "entryPoint.withdrawTo()".
     *                              In case there is a paymaster in the request (or the current deposit is high
     *                              enough), this value will be zero.
     * @return validationData       - Returns the SIG_SUCCESS() OR SIG_FAILUR()

     @dev A signature is valid -> If it's the baseAcount Owner
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external  requireOnlyFromEntryPoint() returns(uint256 validationData){
        validationData = _validateSignature(userOp,userOpHash);
        _validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }

    /**
     * @notice execute function
     * execute a single call from the account.
     * This will use low-level functions call to call the specific function using functionData!!!
     */
    function execute(address to,uint256 value,bytes memory functionData) external requireOnlyFromEntryPointOrOwner() {
        (bool success,bytes memory resultData) = to.call{value:value}(functionData);
        if(!success){
            revert BaseAccount_CallFailedDuringExecute(resultData);
        }
    }
    



    ////////////////////////////////
    // GETTER FUNCTIONS //
    ////////////////////////////////
    function getEntryPoint() public view returns(address){
        return address(i_entryPoint);
    }


    ////////////////////////////////
    // INTERNAL FUNCTIONS //
    ////////////////////////////////

     /**
     * @notice _validateSignature function
     * @notice This function verifies using hash and signature that this signature is signed by the owner of this contract!!! 
     * @notice Validate the signature is valid for this message.

     * @param userOp          - Validate the userOp.signature field.
     * @param userOpHash      - Convenient field: the hash of the request, to check the signature against.
     *                          (also hashes the entrypoint and chain id)
     * @return validationData - Signature and time-range of this operation.
     *                          <20-byte> aggregatorOrSigFail - 0 for valid signature, 1 to mark signature failure,
     *                                    otherwise, an address of an aggregator contract.
     *                          <6-byte> validUntil - Last timestamp this operation is valid at, or 0 for "indefinitely"
     *                          <6-byte> validAfter - first timestamp this operation is valid
     *                          If the account doesn't use time-range, it is enough to return
     *                          SIG_VALIDATION_FAILED value (1) for signature failure.
     *                          Note that the validation code cannot use block.timestamp (or block.number) directly.

     @dev EIP-191 version of signed data!!!!
     */
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
    internal returns (uint256) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);

        if(signer != owner()){
            return SIGNATURE_VALIDATION_FAILED;
        }
        return SIGNATURE_VALIDATION_SUCCESS;
    }


     /**
     * Sends to the entrypoint (msg.sender) the missing funds for this transaction.
     * (e.g. send to the entryPoint more than the minimum required, so that in future transactions
     * it will not be required to send again).
     * @param missingAccountFunds - The minimum value this method should send the entrypoint.
     *                              This value MAY be zero, in case there is enough deposit,
     *                              or the userOp has a paymaster.
     */                       
    function _payPrefund(uint256 missingAccountFunds) internal {
        if(missingAccountFunds != 0){
            (bool success,) = payable(msg.sender).call{
                value:missingAccountFunds
            }("");
            if(!success){
                revert();
            }
        }
    }


    /**
     * Validate the nonce of the UserOperation.
     * This method may validate the nonce requirement of this account.
     * The actual nonce uniqueness is managed by the EntryPoint, and thus no other
     * action is needed by the account itself.
     * @param nonce to validate
     */
    function _validateNonce(uint256 nonce) internal view virtual {}


}