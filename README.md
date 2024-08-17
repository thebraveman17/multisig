# Multi-signature wallet

This wallet allows for the creation of a secure "m out of n" or "n out of n" multi-signature setup. In this type of wallet, multiple owners (n) can be assigned, and a minimum number of approvals (m) are required to execute transactions.

## Key Features:
- **Flexible Approval Requirements**: You can set up configurations such as "4 out of 7" (where 4 out of the 7 owners must approve a transaction) or "3 out of 3" (where all 3 owners must approve).
- **Owner Limits**:
  - **Minimum Owners**: 1 (allowing for a "1 out of 1" setup, though it may not provide the full benefits of multi-signature security).
  - **Maximum Owners**: 255 (the upper limit is set by the ```uint8``` data type used to store the number of owners).
- **Security**: Multi-signature wallets enhance security by requiring multiple approvals, reducing the risk of unauthorized transactions.

This setup provides a versatile and secure solution for managing shared assets or requiring multiple approvals for important transactions.
