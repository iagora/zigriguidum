pub const ActionType = enum {
    TakeTokens,
    ReserveCard,
    PurchaseCard,
};

pub const Action = struct {
    actionType: ActionType,
    tokens: [5]u8, // For TakeTokens
    cardIndex: ?usize, // For ReserveCard and PurchaseCard
    tier: ?u8, // For ReserveCard and PurchaseCard
    fromReserve: ?bool, // For PurchaseCard

    pub fn takeTokens(tokens: [5]u8) Action {
        return Action{
            .actionType = ActionType.TakeTokens,
            .tokens = tokens,
            .cardIndex = null,
            .tier = null,
            .fromReserve = null,
        };
    }

    pub fn reserveCard(cardIndex: usize, tier: u8) Action {
        return Action{
            .actionType = ActionType.ReserveCard,
            .tokens = [5]u8{},
            .cardIndex = cardIndex,
            .tier = tier,
            .fromReserve = null,
        };
    }

    pub fn purchaseCard(cardIndex: usize, tier: u8, fromReserve: bool) Action {
        return Action{
            .actionType = ActionType.PurchaseCard,
            .tokens = [5]u8{},
            .cardIndex = cardIndex,
            .tier = tier,
            .fromReserve = fromReserve,
        };
    }
};
