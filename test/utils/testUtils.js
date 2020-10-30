/**
 * Convenience method to assert that the return of the given block when invoked or promise causes a
 * revert to occur, with an optional revert message.
 * @param blockOrPromise The JS block (i.e. function that when invoked returns a promise) or a promise itself
 * @param reason Optional reason string to search for in revert message
 */
const assertRevert = async (blockOrPromise, reason) => {
	let errorCaught = false;
	try {
		const result = typeof blockOrPromise === 'function' ? blockOrPromise() : blockOrPromise;
		await result;
	} catch (error) {
		assert.include(error.message, 'revert');
		if (reason) {
			assert.include(error.message, reason);
		}
		errorCaught = true;
	}

	assert.equal(errorCaught, true, 'Operation did not revert as expected');
};

/**
 *  Translates an amount to Eth unit (10^18).
 *  @param amount The amount you want to re-base to UNIT
 */
const toEth = amount => web3.utils.toBN(web3.utils.toWei(amount.toString(), 'ether'));
const fromEth = amount => web3.utils.fromWei(amount, 'ether');

const sign = async (message, account) => {
	let sig = await web3.eth.sign(message, account)
	let v = parseInt(sig.substr(sig.length - 2), 16) + 27
	return sig.substr(0, sig.length - 2) + v.toString(16)
}

module.exports = {
	assertRevert,
	toEth,
	fromEth,
	sign
};
