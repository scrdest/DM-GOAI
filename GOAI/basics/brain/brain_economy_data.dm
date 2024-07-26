

#define GOAI_BRAIN_ADD_CONTRACT(Brain, Contract) if(TRUE) {\
	if(!isnull(Brain) && !isnull(Contract)) { \
		if(isnull(Brain.active_contracts)) { Brain.active_contracts = list() }; \
		Brain.active_contracts[ref(Contract)] = Contract; \
	} \
};

/datum/brain
	// An assoc list tracking all our active trade contracts.
	var/list/active_contracts = null

	// An assoc map of what kind of things do we want to trade for each need
	// for use with the personality-based lookup procs.
	var/list/preferred_trades = null
