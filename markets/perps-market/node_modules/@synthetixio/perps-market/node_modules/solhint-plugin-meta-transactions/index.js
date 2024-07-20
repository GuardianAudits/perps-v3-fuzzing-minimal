const BaseChecker = require("solhint/lib/rules/base-checker");

const ruleIdSender = "no-msg-sender";

const metaSender = {
	type: "best-practices",

	docs: {
		description: "Disallow usage of msg.sender.",
		category: "Security",
	},

	isDefault: false,
	recommended: false,
	defaultSetup: "error",
	fixable: false,
	schema: null
};

class MsgSenderChecker extends BaseChecker {
	constructor(reporter) {
		super(reporter, ruleIdSender, metaSender);
	}

	MemberAccess(node) {
		if (node.expression.name === "msg" && node.memberName === "sender") {
			this.error(node, "Usage of msg.sender is disallowed.");
		}
	}
}

const ruleIdData = "no-msg-data";

const metaData = {
	type: "best-practices",

	docs: {
		description: "Disallow usage of msg.data.",
		category: "Security",
	},

	isDefault: false,
	recommended: false,
	defaultSetup: "error",
	fixable: false,
	schema: null
};

class MsgDataChecker extends BaseChecker {
	constructor(reporter) {
		super(reporter, ruleIdData, metaData);
	}

	MemberAccess(node) {
		if (node.expression.name === "msg" && node.memberName === "data") {
			this.error(node, "Usage of msg.data is disallowed.");
		}
	}
}

module.exports = [MsgSenderChecker, MsgDataChecker];