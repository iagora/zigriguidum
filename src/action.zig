pub const ActionType = enum {
    TakeTokens,
    ReserveCard,
    PurchaseCard,
};

pub const Action = struct {
    actionType: ActionType,
    tokens: [5]u8, // For TakeTokens
    cardID: ?u128, // For ReserveCard and PurchaseCard

    pub fn takeTokens(tokens: [5]u8) Action {
        return Action{
            .actionType = ActionType.TakeTokens,
            .tokens = tokens,
            .cardID = null,
        };
    }

    pub fn reserveCard(cardID: u128) Action {
        return Action{
            .actionType = ActionType.ReserveCard,
            .tokens = [5]u8{ 0, 0, 0, 0, 0 },
            .cardID = cardID,
        };
    }

    pub fn purchaseCard(cardID: u128) Action {
        return Action{
            .actionType = ActionType.PurchaseCard,
            .tokens = [5]u8{ 0, 0, 0, 0, 0 },
            .cardID = cardID,
        };
    }
};
