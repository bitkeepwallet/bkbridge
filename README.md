# BitKeep Bridge

## About 
The library contains a smart contract for EVM-based blockchains (Ethereum, BNB Chain, etc.), which serves as a critical part of the BitKeep Bridge order-protocol.

The contract allows users to exchange tokens across different chains, such as: ETH(USDC) to BNB Chain(USDT).

## Deployments 
The protocol uses the same address on most EVMs, deployed using CREATE2 Factory, and differs in the Zksync-era chain and Tron chain, as follows:

<table>
  <tr>
    <th>Network</th>
    <th>BKBridgeRouter</th>
  </tr>

  <tr>
    <td>Ethereum</td>
    <td rowspan="6">
      <a href="https://bscscan.com/address/0x22cE84A7F86662b78E49C6ec9E51D60FddE7b70A#code">0x22cE84A7F86662b78E49C6ec9E51D60FddE7b70A</a>
    </td>
  </tr>

  <tr>
    <td>BNB Chain</td>
  </tr>
  <tr>
    <td>Polygon</td>
  </tr>
  <tr>
    <td>Optimism</td>
  </tr>
  <tr>
    <td>Arbitrum</td>
  </tr>
  <tr>
    <td>Avalanche C-Chain</td>
  </tr>

  <tr>
    <td>Zksync-era</td>
    <td>
      <a href="https://explorer.zksync.io/address/0x446d8e69bd642EA000D9a631C147FBd4013e5F36">0x446d8e69bd642EA000D9a631C147FBd4013e5F36</a>
    </td>
  </tr>

  <tr>
    <td>Tron</td>
    <td>
      <a href="https://tronscan.org/#/contract/TF4eMWEwDdweaB2M1mpeZfbBajRkb7jAyz">TF4eMWEwDdweaB2M1mpeZfbBajRkb7jAyz</a>
    </td>
  </tr>
</table>

## Audit 
This protocol is completely audited by Certik, [Audit Report](https://github.com/bitkeepwallet/bkbridge/blob/main/audit/Certik%20Audit%20Report-BKBridge.pdf)
